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
                Label("Lock Message with Facial Expressions", systemImage: "faceid")
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.borderedProminent)
            .disabled(!viewModel.canProceedToRecording)
            .padding()
            
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
            VStack(spacing: 24) {
                // Success header
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.green)
                    
                    Text("Message Locked! 🎉")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Your secret message is now encrypted")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding()
                
                // GIF preview
                if let gifURL = viewModel.generatedGIFURL {
                    VStack(spacing: 12) {
                        AnimatedGIFView(url: gifURL)
                            .frame(height: 300)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(16)
                            .shadow(radius: 4)
                        
                        if let message = viewModel.createdMessage {
                            HStack(spacing: 8) {
                                Image(systemName: "number.circle.fill")
                                    .foregroundStyle(.secondary)
                                Text("Message ID: \(message.id)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                        }
                        
                        // Expression sequence
                        VStack(spacing: 8) {
                            Text("Expression Sequence:")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            HStack(spacing: 8) {
                                ForEach(Array(viewModel.expressionRecorder.recordedExpressions.enumerated()), id: \.offset) { index, expr in
                                    VStack(spacing: 4) {
                                        Text(expr.emoji)
                                            .font(.title2)
                                        Text(expr.displayName)
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                    .padding(8)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(8)
                                }
                            }
                        }
                    }
                    .padding()
                    
                    // Action buttons
                    VStack(spacing: 12) {
                        ShareLink(
                            item: gifURL,
                            preview: SharePreview(
                                "Secret Message",
                                image: Image(systemName: "lock.fill")
                            )
                        ) {
                            Label("Share GIF", systemImage: "square.and.arrow.up")
                                .frame(maxWidth: .infinity)
                                .padding()
                        }
                        .buttonStyle(.borderedProminent)
                        
                        Button {
                            viewModel.reset(detector: faceDetector)
                        } label: {
                            Label("Create Another Message", systemImage: "plus.circle")
                                .frame(maxWidth: .infinity)
                                .padding()
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                }
            }
        }
    }
}

#Preview {
    EncodeView()
}
