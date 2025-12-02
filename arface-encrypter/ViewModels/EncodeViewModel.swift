//
//  EncodeViewModel.swift
//  arface-encrypter
//
//  Created by Claude Code
//

import Foundation
import Observation
import UIKit

/// View model for the encode flow
/// Manages the entire message encoding process from text input to GIF generation
@Observable
class EncodeViewModel {
    
    // MARK: - State Properties
    
    var messageText: String = ""
    var expressionRecorder = ExpressionRecorder()
    
    var generatedGIFURL: URL?
    var isGenerating = false
    var errorMessage: String?
    var createdMessage: Message?
    
    // Track AI-generated frames as they're created
    var generatedFrames: [UIImage] = []
    
    // MARK: - Encoding Steps
    
    enum EncodingStep {
        case enterMessage
        case recordExpressions
        case generatingGIF
        case shareGIF
    }
    
    var currentStep: EncodingStep = .enterMessage
    
    // MARK: - Computed Properties
    
    var canProceedToRecording: Bool {
        !messageText.isEmpty && messageText.count <= 100
    }
    
    var characterCountColor: String {
        messageText.count > 100 ? "red" : "secondary"
    }
    
    // MARK: - Public Methods
    
    /// Start the expression recording process
    func startExpressionRecording(with detector: ARFaceDetector) {
        print("🎬 Starting expression recording")
        currentStep = .recordExpressions
        Task { @MainActor in
            detector.startTracking()
        }
        expressionRecorder.startRecording()
    }
    
    /// Handle a detected expression from ARFaceDetector
    func handleDetectedExpression(_ expression: FaceExpression, detector: ARFaceDetector) {
        guard currentStep == .recordExpressions else { return }
        
        if expressionRecorder.recordExpression(expression) {
            // Provide haptic feedback
            HapticManager.expressionDetected()
            
            // If recording is complete, generate and upload
            if expressionRecorder.isComplete {
                Task {
                    await generateAndUploadMessage(detector: detector)
                }
            }
        }
    }
    
    /// Generate GIF and upload message to database
    func generateAndUploadMessage(detector: ARFaceDetector) async {
        print("🚀 Generating and uploading message")
        currentStep = .generatingGIF
        isGenerating = true
        await MainActor.run {
            detector.stopTracking()
        }
        
        do {
            // 1. Create message in database first (to get ID)
            let hash = expressionRecorder.getExpressionHash()
            print("📝 Expression hash: \(hash)")
            
            createdMessage = try await MessageService.shared.createMessage(
                expressionHash: hash,
                message: messageText,
                expressionList: hash
            )
            
            guard let message = createdMessage else {
                throw EncodingError.messageCreationFailed
            }
            
            // 2. Generate GIF with message ID
            print("🎨 Generating GIF with message ID: \(message.id)")
            
            // Clear previous frames
            generatedFrames = []
            
            let gifURL = try await GIFGenerator.generateGIF(
                expressions: expressionRecorder.recordedExpressions,
                avatar: UserSettings.shared.selectedAvatar,
                messageID: "\(message.id)",
                onFrameGenerated: { @MainActor image, index in
                    // Add frame as it's generated for real-time preview
                    self.generatedFrames.append(image)
                    print("📸 Frame \(index + 1) ready for preview")
                }
            )
            
            generatedGIFURL = gifURL
            currentStep = .shareGIF
            
            // Increment encoded count
            UserSettings.shared.incrementEncodedCount()
            
            // Success haptic
            HapticManager.sequenceComplete()
            print("✅ Message encoded successfully!")
            
        } catch {
            print("❌ Error during encoding: \(error.localizedDescription)")
            handleError(error)
            currentStep = .enterMessage
        }
        
        isGenerating = false
    }
    
    /// Reset the entire encoding flow
    func reset(detector: ARFaceDetector) {
        print("🔄 Resetting encode flow")
        messageText = ""
        expressionRecorder.reset()
        generatedGIFURL = nil
        errorMessage = nil
        createdMessage = nil
        generatedFrames = []
        currentStep = .enterMessage
        Task { @MainActor in
            detector.stopTracking()
        }
    }
    
    /// Cancel the current encoding process
    func cancel(detector: ARFaceDetector) {
        print("❌ Canceling encode flow")
        Task { @MainActor in
            detector.stopTracking()
        }
        expressionRecorder.reset()
        generatedFrames = []
        currentStep = .enterMessage
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
        } else if let encodingError = error as? EncodingError {
            errorMessage = encodingError.localizedDescription
        } else {
            errorMessage = error.localizedDescription
        }
        
        HapticManager.error()
    }
}

// MARK: - Custom Errors

enum EncodingError: LocalizedError {
    case messageCreationFailed
    case gifGenerationFailed
    case invalidMessageLength
    
    var errorDescription: String? {
        switch self {
        case .messageCreationFailed:
            return "Failed to create message in database"
        case .gifGenerationFailed:
            return "Failed to generate GIF"
        case .invalidMessageLength:
            return "Message must be between 1 and 100 characters"
        }
    }
}

