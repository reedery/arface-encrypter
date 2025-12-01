//
//  EncodeViewModel.swift
//  arface-encrypter
//
//  Created by Claude Code
//

import Foundation
import Observation
import Combine

/// View model for the encode flow
/// Manages the entire message encoding process from text input to GIF generation
@Observable
@MainActor
class EncodeViewModel {
    
    // MARK: - State Properties
    
    var messageText: String = ""
    var expressionRecorder = ExpressionRecorder()
    
    // Use @ObservationIgnored for ObservableObject properties
    @ObservationIgnored var faceDetector = ARFaceDetector()
    @ObservationIgnored private var cancellables = Set<AnyCancellable>()
    
    var generatedGIFURL: URL?
    var isGenerating = false
    var errorMessage: String?
    var createdMessage: Message?
    
    // Track current expression separately so @Observable can track it
    var currentDetectedExpression: FaceExpression?
    
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
    
    // MARK: - Initialization
    
    init() {
        // Observe the face detector's currentExpression changes
        faceDetector.$currentExpression
            .sink { [weak self] expression in
                guard let self = self else { return }
                Task { @MainActor in
                    self.currentDetectedExpression = expression
                    if let expr = expression {
                        self.handleDetectedExpression(expr)
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    /// Start the expression recording process
    func startExpressionRecording() {
        print("🎬 Starting expression recording")
        currentStep = .recordExpressions
        faceDetector.startTracking()
        expressionRecorder.startRecording()
    }
    
    /// Handle a detected expression from ARFaceDetector
    func handleDetectedExpression(_ expression: FaceExpression) {
        guard currentStep == .recordExpressions else { return }
        
        if expressionRecorder.recordExpression(expression) {
            // Provide haptic feedback
            HapticManager.expressionDetected()
            
            // If recording is complete, generate and upload
            if expressionRecorder.isComplete {
                Task {
                    await generateAndUploadMessage()
                }
            }
        }
    }
    
    /// Generate GIF and upload message to database
    @MainActor
    func generateAndUploadMessage() async {
        print("🚀 Generating and uploading message")
        currentStep = .generatingGIF
        isGenerating = true
        faceDetector.stopTracking()
        
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
            let gifURL = try await GIFGenerator.generateGIF(
                expressions: expressionRecorder.recordedExpressions,
                avatar: UserSettings().selectedAvatar,
                messageID: "\(message.id)"
            )
            
            generatedGIFURL = gifURL
            currentStep = .shareGIF
            
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
    func reset() {
        print("🔄 Resetting encode flow")
        messageText = ""
        expressionRecorder.reset()
        generatedGIFURL = nil
        errorMessage = nil
        createdMessage = nil
        currentStep = .enterMessage
        faceDetector.stopTracking()
    }
    
    /// Cancel the current encoding process
    func cancel() {
        print("❌ Canceling encode flow")
        faceDetector.stopTracking()
        expressionRecorder.reset()
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

