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
            .navigationTitle("Encode Message")
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
            
            VStack(spacing: 12) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.tint)
                
                Text("Write a Secret Message")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Your message will be encrypted using facial expressions")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Spacer()
            
            VStack(spacing: 8) {
                TextField("Type your message", text: $viewModel.messageText, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(3...6)
                    .padding(.horizontal)
                
                HStack {
                    Spacer()
                    Text("\(viewModel.messageText.count)/100")
                        .font(.caption)
                        .foregroundStyle(viewModel.messageText.count > 100 ? .red : .secondary)
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
                VStack(spacing: 8) {
                    Text("Expression \(viewModel.expressionRecorder.currentStep + 1) of 5")
                        .font(.headline)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial)
                        .cornerRadius(20)
                    
                    if let currentExpr = faceDetector.currentExpression {
                        Text("\(currentExpr.emoji) \(currentExpr.displayName)")
                            .font(.title3)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(.green.opacity(0.8))
                            .foregroundStyle(.white)
                            .cornerRadius(20)
                    }
                }
                .padding()
            }
            
            // Progress indicator
            VStack(spacing: 16) {
                // Progress bar
                ProgressView(value: Double(viewModel.expressionRecorder.currentStep), total: 5.0)
                    .padding(.horizontal)
                
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
                        } else if index == viewModel.expressionRecorder.currentStep {
                            // Current expression
                            VStack(spacing: 4) {
                                Circle()
                                    .fill(Color.blue.opacity(0.3))
                                    .frame(width: 32, height: 32)
                                    .overlay {
                                        ProgressView()
                                    }
                                Text("\(index + 1)")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(8)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(12)
                        } else {
                            // Pending expression
                            VStack(spacing: 4) {
                                Circle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(width: 32, height: 32)
                                Text("\(index + 1)")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(8)
                        }
                    }
                }
                .padding(.horizontal)
                
                Button("Cancel") {
                    viewModel.cancel(detector: faceDetector)
                }
                .buttonStyle(.bordered)
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
            
            ProgressView()
                .scaleEffect(1.5)
                .padding()
            
            VStack(spacing: 8) {
                Text("Creating Your Encrypted Message")
                    .font(.headline)
                
                Text("Generating animated GIF...")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Share GIF View
    
    private var shareGIFView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Success header - no checkmark
                VStack(spacing: 8) {
                    Text("Message Locked! 🎉")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Your secret message is now encrypted")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
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
                        
                        // Expression sequence
                        VStack(spacing: 8) {
                            Text("Expression Sequence:")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            HStack(spacing: 6) {
                                ForEach(Array(viewModel.expressionRecorder.recordedExpressions.enumerated()), id: \.offset) { index, expr in
                                    VStack(spacing: 2) {
                                        Text(expr.emoji)
                                            .font(.title3)
                                        Text("\(index + 1)")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                    .padding(6)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(6)
                                }
                            }
                        }
                        
                        // Action buttons
                        VStack(spacing: 12) {
                            ShareLink(
                                item: gifURL,
                                preview: SharePreview(
                                    "Secret Message",
                                    image: Image(systemName: "lock.fill")
                                )
                            ) {
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
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
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
    }
}

#Preview {
    EncodeView()
}
