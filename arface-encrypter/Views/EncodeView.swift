//
//  EncodeView.swift
//  arface-encrypter
//
//  Created by ryan reede on 11/30/25.
//

import SwiftUI

struct EncodeView: View {
    @State private var viewModel = EncodeViewModel()
    @State private var userSettings = UserSettings()
    @StateObject private var faceDetector = ARFaceDetector()
    @State private var showingShareSheet = false
    
    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.currentStep {
                case .enterMessage:
                    messageInputView
                case .recordExpressions:
                    expressionRecordingView
                case .generatingGIF:
                    generatingView
                case .shareGIF:
                    shareGIFView
                }
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                if let error = viewModel.errorMessage {
                    Text(error)
                }
            }
        }
    }
    
    // MARK: - Message Input View
    
    private var messageInputView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.green)
                    .padding(.bottom, 8)
                
                Text("Create a Secret Message")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Encrypt your message with a unique facial expression sequence")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                
                // How it works info card
                VStack(spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle.fill")
                            .foregroundStyle(.green)
                        Text("How it works")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Spacer()
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "1.circle.fill")
                                .foregroundStyle(.green.opacity(0.7))
                                .font(.caption)
                            Text("Write your secret message")
                                .font(.caption)
                        }
                        HStack(spacing: 8) {
                            Image(systemName: "2.circle.fill")
                                .foregroundStyle(.green.opacity(0.7))
                                .font(.caption)
                            Text("Make 5 random facial expressions")
                                .font(.caption)
                        }
                        HStack(spacing: 8) {
                            Image(systemName: "3.circle.fill")
                                .foregroundStyle(.green.opacity(0.7))
                                .font(.caption)
                            Text("Share the encrypted GIF")
                                .font(.caption)
                        }
                    }
                    .foregroundStyle(.secondary)
                }
                .padding(16)
                .background(Color.green.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal, 24)
            }
            
            Spacer()
            
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "pencil")
                        .foregroundStyle(.secondary)
                    Text("Your Message")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Spacer()
                }
                .padding(.horizontal)
                
                TextField("Type your secret message here...", text: $viewModel.messageText, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(3...6)
                    .padding(.horizontal)
                    .toolbar {
                        ToolbarItemGroup(placement: .keyboard) {
                            Spacer()
                            Button("Done") {
                                hideKeyboard()
                            }
                        }
                    }
                
                HStack {
                    Image(systemName: viewModel.messageText.count > 100 ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                        .font(.caption2)
                        .foregroundStyle(viewModel.messageText.count > 100 ? .red : (viewModel.messageText.isEmpty ? .secondary : .green))
                    Text("\(viewModel.messageText.count)/100 characters")
                        .font(.caption)
                        .foregroundStyle(viewModel.messageText.count > 100 ? .red : .secondary)
                    Spacer()
                }
                .padding(.horizontal)
            }
            
            Spacer()
            
            Button {
                viewModel.startExpressionRecording(with: faceDetector)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "faceid")
                        .font(.system(size: 24, weight: .semibold))
                    Text("Lock Message with your Face!")
                        .fontWeight(.semibold)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                }
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .padding(.horizontal, 20)
                .background(
                    viewModel.canProceedToRecording
                        ? LinearGradient(
                            colors: [Color.green.opacity(0.9), Color.green.opacity(0.7)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        : LinearGradient(
                            colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.3)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                )
                .foregroundColor(viewModel.canProceedToRecording ? .black : .gray)
                .cornerRadius(16)
                .shadow(
                    color: viewModel.canProceedToRecording ? Color.green.opacity(0.4) : Color.clear,
                    radius: 8,
                    x: 0,
                    y: 4
                )
            }
            .disabled(!viewModel.canProceedToRecording)
            .padding(.horizontal)
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Expression Recording View
    
    private var expressionRecordingView: some View {
        VStack(spacing: 0) {
            // Camera view
            ARFaceTrackingView(
                detector: faceDetector,
                showDebugOverlay: false
            )
            .overlay(alignment: .top) {
                VStack(spacing: 12) {
                    // Progress indicator
                    Text("Expression \(viewModel.expressionRecorder.currentStep + 1) of 5")
                        .font(.headline)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial)
                        .cornerRadius(20)
                    
                    // Current expression detected
                    if let currentExpr = faceDetector.currentExpression {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 16))
                            Text("\(currentExpr.emoji) \(currentExpr.displayName)")
                                .font(.title3)
                                .fontWeight(.semibold)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(.green)
                        .foregroundStyle(.white)
                        .cornerRadius(20)
                        .shadow(color: .green.opacity(0.4), radius: 8)
                    } else {
                        // Helpful instructions when no expression detected
                        HStack(spacing: 8) {
                            Image(systemName: faceDetector.detectionActive ? "face.smiling" : "exclamationmark.triangle")
                                .font(.system(size: 14))
                            Text(faceDetector.isNeutral ? "Make an expression & hold it!" : "Hold your expression...")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial)
                        .foregroundStyle(faceDetector.detectionActive ? .primary : Color.orange)
                        .cornerRadius(20)
                    }
                }
                .padding()
            }
            .overlay(alignment: .center) {
                // Face detection guide circle
                if !faceDetector.detectionActive || faceDetector.isNeutral {
                    VStack(spacing: 16) {
                        Circle()
                            .stroke(
                                faceDetector.detectionActive ? Color.blue.opacity(0.5) : Color.orange.opacity(0.5),
                                style: StrokeStyle(lineWidth: 3, dash: [10, 5])
                            )
                            .frame(width: 250, height: 250)
                        
                        Text("Position your face here")
                            .font(.caption)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(.black.opacity(0.6))
                            .cornerRadius(8)
                    }
                }
            }
            
            // Progress indicator
            VStack(spacing: 16) {
                // Helpful tip banner
                HStack(spacing: 8) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(.yellow)
                    Text("Hold each expression for 1 second, then return to neutral")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(10)
                .padding(.horizontal)
                
                // Progress bar
                ProgressView(value: Double(viewModel.expressionRecorder.currentStep), total: 5.0)
                    .padding(.horizontal)
                    .tint(.green)
                
                // Expression chips
                HStack(spacing: 12) {
                    ForEach(0..<5, id: \.self) { index in
                        if index < viewModel.expressionRecorder.recordedExpressions.count {
                            // Recorded expression
                            VStack(spacing: 4) {
                                Text(viewModel.expressionRecorder.recordedExpressions[index].emoji)
                                    .font(.system(size: 32))
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                    .font(.caption)
                            }
                            .padding(8)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.green.opacity(0.3), lineWidth: 2)
                            )
                        } else if index == viewModel.expressionRecorder.currentStep {
                            // Current expression
                            VStack(spacing: 4) {
                                Circle()
                                    .fill(Color.blue.opacity(0.3))
                                    .frame(width: 32, height: 32)
                                    .overlay {
                                        Image(systemName: "circle.dotted")
                                            .font(.system(size: 28))
                                            .foregroundStyle(.blue)
                                    }
                                Text("Next")
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.blue)
                            }
                            .padding(8)
                            .background(Color.blue.opacity(0.15))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.blue, lineWidth: 2)
                            )
                        } else {
                            // Pending expression
                            VStack(spacing: 4) {
                                Circle()
                                    .fill(Color.gray.opacity(0.1))
                                    .frame(width: 32, height: 32)
                                    .overlay {
                                        Text("\(index + 1)")
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundStyle(.secondary)
                                    }
                                Text("Wait")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(8)
                        }
                    }
                }
                .padding(.horizontal)
                
                // Available expressions
                VStack(spacing: 8) {
                    Text("Available Expressions")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                    
                    HStack(spacing: 16) {
                        VStack(spacing: 2) {
                            Text("😘")
                                .font(.system(size: 24))
                            Text("Smooch")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        
                        VStack(spacing: 2) {
                            Text("😁")
                                .font(.system(size: 24))
                            Text("Smile")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        
                        VStack(spacing: 2) {
                            Text("😛")
                                .font(.system(size: 24))
                            Text("Tongue")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        
                        VStack(spacing: 2) {
                            Text("😮")
                                .font(.system(size: 24))
                            Text("Surprise")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        
                        VStack(spacing: 2) {
                            Text("😉")
                                .font(.system(size: 24))
                            Text("Wink")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.vertical, 8)
                .padding(.horizontal)
                .background(Color.blue.opacity(0.05))
                .cornerRadius(12)
                .padding(.horizontal)
                
                Button {
                    viewModel.cancel(detector: faceDetector)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "xmark.circle")
                        Text("Cancel")
                    }
                }
                .buttonStyle(.bordered)
                .tint(.red)
                .padding(.bottom)
            }
            .padding(.vertical)
            .background(.ultraThinMaterial)
        }
        .onChange(of: faceDetector.currentExpression) { _, newExpression in
            if let expression = newExpression {
                viewModel.handleDetectedExpression(expression, detector: faceDetector)
            }
        }
        .onDisappear {
            faceDetector.stopTracking()
        }
    }
    
    // MARK: - Generating View
    
    private var generatingView: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Animated icon
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.1))
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 50))
                        .foregroundStyle(.green)
                }
                
                ProgressView()
                    .scaleEffect(1.2)
            }
            
            VStack(spacing: 8) {
                Text("Creating Your Encrypted Message")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                if viewModel.generatedFrames.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.caption)
                        Text("Generating AI-enhanced frames...")
                            .font(.subheadline)
                    }
                    .foregroundStyle(.secondary)
                } else {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.green)
                        Text("Generated \(viewModel.generatedFrames.count) of 5 frames")
                            .font(.subheadline)
                    }
                    .foregroundStyle(.secondary)
                }
            }
            
            // Show generated frames as they come in
            if !viewModel.generatedFrames.isEmpty {
                HStack(spacing: 8) {
                    ForEach(0..<5, id: \.self) { index in
                        if index < viewModel.generatedFrames.count {
                            // Show generated frame
                            Image(uiImage: viewModel.generatedFrames[index])
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 50, height: 50)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.green, lineWidth: 2)
                                )
                        } else {
                            // Placeholder for pending frame
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 50, height: 50)
                                .overlay(
                                    ProgressView()
                                        .scaleEffect(0.7)
                                )
                        }
                    }
                }
                .padding()
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Share GIF View
    
    private var shareGIFView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Success header with icon
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.green)
                    
                    Text("Message Locked! 🎉")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Your secret message is now encrypted in this GIF")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top)
                
                // GIF preview - exactly 256px square
                if let gifURL = viewModel.generatedGIFURL {
                    VStack(spacing: 16) {
                        AnimatedGIFView(url: gifURL)
                            .frame(width: 256, height: 256)
                            .background(Color.gray.opacity(0.05))
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                        
                        // Expression sequence with instructions
                        VStack(spacing: 12) {
                            HStack(spacing: 6) {
                                Image(systemName: "key.fill")
                                    .font(.caption)
                                    .foregroundStyle(.green)
                                Text("Your Unlock Sequence")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                            
                            HStack(spacing: 8) {
                                ForEach(Array(viewModel.expressionRecorder.recordedExpressions.enumerated()), id: \.offset) { index, expr in
                                    VStack(spacing: 4) {
                                        Text(expr.emoji)
                                            .font(.title2)
                                        Text("\(index + 1)")
                                            .font(.caption2)
                                            .fontWeight(.semibold)
                                            .foregroundStyle(.white)
                                            .padding(4)
                                            .background(Color.green)
                                            .clipShape(Circle())
                                    }
                                    .padding(10)
                                    .background(Color.green.opacity(0.1))
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.green.opacity(0.3), lineWidth: 1.5)
                                    )
                                    
                                    if index < viewModel.expressionRecorder.recordedExpressions.count - 1 {
                                        Image(systemName: "arrow.right")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                            
                            Text("Others will need to recreate this sequence to unlock your message")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                        
                        // Action buttons
                        VStack(spacing: 12) {
                            Button {
                                showingShareSheet = true
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.system(size: 20, weight: .semibold))
                                    Text("Share GIF")
                                        .font(.headline)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(
                                        colors: [Color.green, Color.green.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(16)
                                .shadow(color: .green.opacity(0.3), radius: 8, x: 0, y: 4)
                            }
                            
                            Button {
                                viewModel.reset(detector: faceDetector)
                            } label: {
                                Label("Create Another Message", systemImage: "plus.circle")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.primary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                            }
                            .buttonStyle(.bordered)
                        }
                        .padding(.horizontal)
                        
                        Spacer()
                        
                        // Message ID at bottom
                        if let message = viewModel.createdMessage {
                            HStack(spacing: 6) {
                                Image(systemName: "number.circle.fill")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                                Text("Message ID: \(message.id)")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                            .padding(.bottom, 8)
                        }
                    }
                }
            }
        }
        .gifShareSheet(isPresented: $showingShareSheet, gifURL: viewModel.generatedGIFURL)
    }
    
    // MARK: - Helper Methods
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

#Preview {
    EncodeView()
}
