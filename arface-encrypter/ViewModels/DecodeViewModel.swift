//
//  DecodeViewModel.swift
//  arface-encrypter
//
//  Created by ryan reede on 11/30/25.
//

import Foundation
import Observation

/// View model for the decode flow
/// Manages message fetching and display from the database
@MainActor
@Observable
final class DecodeViewModel {
    
    // MARK: - State Properties (Message List)
    
    var messages: [Message] = []
    var isLoading = false
    var errorMessage: String?
    
    // MARK: - State Properties (Decoding Flow)
    
    var isDecoding = false
    var decodingRecorder = ExpressionRecorder()
    var selectedGIFURL: URL?
    var extractedMessageID: String?
    var decodedMessage: Message?
    var attemptError: String?
    
    // MARK: - Decoding Steps
    
    enum DecodingStep {
        case selectGIF
        case performExpressions
        case validating
        case messageRevealed
        case incorrectSequence
    }
    var currentDecodingStep: DecodingStep = .selectGIF
    
    // MARK: - Public Methods (Message List)
    
    /// Fetch all messages from the database
    func fetchMessages() async {
        isLoading = true
        errorMessage = nil
        
        do {
            messages = try await MessageService.shared.fetchAllMessages()
            print("📋 Fetched \(messages.count) messages")
        } catch {
            print("❌ Error fetching messages: \(error.localizedDescription)")
            handleError(error)
        }
        
        isLoading = false
    }
    
    // MARK: - Public Methods (Decoding Flow)
    
    /// Start the decoding flow
    func startDecoding(with detector: ARFaceDetector) {
        print("🎬 Starting decoding flow")
        isDecoding = true
        currentDecodingStep = .performExpressions
        detector.startTracking()
        decodingRecorder.startRecording()
    }
    
    /// Select a GIF to decode and extract message ID
    func selectGIF(url: URL) async {
        print("🎬 Selecting GIF for decoding: \(url.lastPathComponent)")
        selectedGIFURL = url
        extractedMessageID = await MessageIDExtractor.extractMessageID(from: url)
        
        if extractedMessageID != nil {
            print("✅ Message ID extracted, ready for expressions")
        } else {
            print("❌ Could not extract message ID from GIF")
            attemptError = "Could not read message ID from GIF. Please make sure you selected a valid encrypted message."
            HapticManager.error()
        }
    }
    
    /// Handle a detected expression during decoding
    func handleDecodingExpression(_ expression: FaceExpression, detector: ARFaceDetector) {
        guard currentDecodingStep == .performExpressions else { return }
        
        if decodingRecorder.recordExpression(expression) {
            HapticManager.expressionDetected()
            
            if decodingRecorder.isComplete {
                Task {
                    await validateSequence(with: detector)
                }
            }
        }
    }
    
    /// Validate the performed expression sequence against the database
    func validateSequence(with detector: ARFaceDetector) async {
        print("🔍 Validating expression sequence...")
        currentDecodingStep = .validating
        detector.stopTracking()
        
        do {
            let attemptedHash = decodingRecorder.getExpressionHash()
            print("   Attempted sequence: \(attemptedHash)")
            
            // Check if a GIF was loaded (optional - allows decoding without GIF hint)
            if selectedGIFURL == nil {
                print("⚠️ No GIF was loaded (attempting blind decode)")
            }
            
            if let message = try await MessageService.shared.fetchMessage(byHash: attemptedHash) {
                // Success! Sequence matches
                print("✅ Message unlocked: \(message.message ?? "")")
                decodedMessage = message
                currentDecodingStep = .messageRevealed
                HapticManager.sequenceComplete()
            } else {
                // Wrong sequence
                print("❌ No message found with this sequence")
                let hint = selectedGIFURL == nil ? "\n\nTip: Try loading the GIF to see the sequence!" : ""
                attemptError = "Incorrect sequence!\n\nYou performed:\n\(attemptedHash.replacingOccurrences(of: ",", with: " → "))\n\nThis doesn't match any encrypted message.\(hint)"
                currentDecodingStep = .incorrectSequence
                HapticManager.error()
            }
        } catch {
            print("❌ Error validating sequence: \(error.localizedDescription)")
            attemptError = "Error validating sequence: \(error.localizedDescription)"
            currentDecodingStep = .incorrectSequence
            HapticManager.error()
        }
    }
    
    /// Reset the decoding flow
    func resetDecoding(with detector: ARFaceDetector) {
        print("🔄 Resetting decoding flow")
        isDecoding = false
        decodingRecorder.reset()
        selectedGIFURL = nil
        extractedMessageID = nil
        decodedMessage = nil
        attemptError = nil
        currentDecodingStep = .selectGIF
        detector.stopTracking()
    }
    
    /// Retry the decoding attempt (keeps GIF loaded if present)
    func retryDecoding(with detector: ARFaceDetector) {
        print("🔁 Retrying decoding")
        decodingRecorder.reset()
        attemptError = nil
        decodedMessage = nil
        currentDecodingStep = .performExpressions
        detector.startTracking()
        decodingRecorder.startRecording()
    }
    
    // MARK: - Private Methods
    
    private func handleError(_ error: Error) {
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet:
                errorMessage = "No internet connection. Please check your network."
            case .timedOut:
                errorMessage = "Request timed out. Please try again."
            default:
                errorMessage = "Network error: \(urlError.localizedDescription)"
            }
        } else {
            errorMessage = error.localizedDescription
        }
    }
}
