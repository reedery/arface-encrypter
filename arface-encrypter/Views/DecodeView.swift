//
//  DecodeView.swift
//  arface-encrypter
//
//  Created by ryan reede on 11/30/25.
//

import SwiftUI

struct DecodeView: View {
    @State private var viewModel = DecodeViewModel()
    @StateObject private var decodingDetector = ARFaceDetector()
    @State private var showingImagePicker = false
    
    var body: some View {
        NavigationStack {
            if viewModel.isDecoding {
                decodingFlowView
            } else {
                messageListView
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker { url in
                Task {
                    await viewModel.selectGIF(url: url)
                }
            }
        }
    }
    
    // MARK: - Message List View
    
    private var messageListView: some View {
        VStack(spacing: 0) {
            VStack(spacing: 12) {
                Image(systemName: "lock.open.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.teal)
                
                Text("Unlock a Secret Message")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Use your face to perform the expression sequence")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding(.top, 100)
            .padding(.bottom, 30)
            
            Button {
                viewModel.startDecoding(with: decodingDetector)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "faceid")
                        .font(.system(size: 24, weight: .semibold))
                    Text("Decode a Message")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .padding(.horizontal, 20)
                .background(
                    LinearGradient(
                        colors: [Color.teal, Color.teal.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundStyle(.white)
                .cornerRadius(16)
                .shadow(color: .teal.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .padding(.horizontal, 24)
            
            Spacer()
        }
        .frame(maxHeight: .infinity, alignment: .top)
    }
    
    // MARK: - Decoding Flow View
    
    private var decodingFlowView: some View {
        Group {
            switch viewModel.currentDecodingStep {
            case .selectGIF:
                Text("Select GIF...")
            case .performExpressions:
                performExpressionsView
            case .validating:
                validatingView
            case .messageRevealed:
                messageRevealedView
            case .incorrectSequence:
                incorrectSequenceView
            }
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    viewModel.resetDecoding(with: decodingDetector)
                }
            }
        }
    }
    
    private var performExpressionsView: some View {
        VStack(spacing: 0) {
            // Full screen camera view
            ARFaceTrackingView(
                detector: decodingDetector,
                showDebugOverlay: false
            )
            .overlay(alignment: .topLeading) {
                // Top instruction
                VStack {
                    Text("Perform expression \(viewModel.decodingRecorder.currentStep + 1) of 5")
                        .font(.headline)
                        .padding(12)
                        .background(.ultraThinMaterial)
                        .cornerRadius(10)
                }
                .padding()
            }
            .overlay(alignment: .topTrailing) {
                // Top right: Small GIF preview or load button
                VStack(spacing: 8) {
                    if let gifURL = viewModel.selectedGIFURL {
                        // Show small GIF preview
                        AnimatedGIFView(url: gifURL)
                            .frame(width: 100, height: 100)
                            .cornerRadius(8)
                            .shadow(color: .black.opacity(0.3), radius: 4)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.white.opacity(0.5), lineWidth: 2)
                            )
                    } else {
                        // Load GIF button
                        Button {
                            showingImagePicker = true
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: "photo.fill")
                                    .font(.title3)
                                Text("Load GIF")
                                    .font(.system(size: 14, weight: .medium))
                                    .fontWeight(.heavy)
                            }
                            .frame(width: 100, height: 100)
                            .background(.ultraThinMaterial)
                            .cornerRadius(8)
                            .shadow(color: .black.opacity(0.4), radius: 4, x: 1, y: 2)
                        }
                    }
                }
                .padding()
            }
            
            // Bottom section: Progress
            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    ForEach(0..<5, id: \.self) { index in
                        if index < viewModel.decodingRecorder.recordedExpressions.count {
                            // Show recorded expression emoji
                            Text(viewModel.decodingRecorder.recordedExpressions[index].emoji)
                                .font(.system(size: 40))
                                .transition(.scale.combined(with: .opacity))
                        } else {
                            // Show empty placeholder
                            Circle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 44, height: 44)
                                .overlay(
                                    Text("\(index + 1)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                )
                        }
                    }
                }
                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: viewModel.decodingRecorder.recordedExpressions.count)
                
                Text("Return to neutral between expressions")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
        }
        .onChange(of: decodingDetector.currentExpression) { _, newValue in
            if let expr = newValue {
                viewModel.handleDecodingExpression(expr, detector: decodingDetector)
            }
        }
        .onDisappear {
            decodingDetector.stopTracking()
        }
    }
    
    private var validatingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Validating sequence...")
                .font(.headline)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
    
    private var messageRevealedView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Success icon
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.green)
                    .transition(.scale.combined(with: .opacity))
                
                Text("Message Unlocked!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .transition(.opacity)
                
                // Decoded message
                if let message = viewModel.decodedMessage {
                    VStack(spacing: 16) {
                        Text(message.message ?? "")
                            .font(.title3)
                            .multilineTextAlignment(.center)
                            .padding(20)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.green.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.green.opacity(0.3), lineWidth: 2)
                                    )
                            )
                            .transition(.scale.combined(with: .opacity))
                        
                        // Message details
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Message ID:")
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text("\(message.id)")
                                    .fontWeight(.medium)
                            }
                            
                            HStack {
                                Text("Created:")
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text(message.createdAt, style: .date)
                                    .fontWeight(.medium)
                            }
                            
                            if let expressions = message.expressions {
                                HStack {
                                    Text("Sequence:")
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    HStack(spacing: 4) {
                                        ForEach(expressions, id: \.self) { expr in
                                            Text(expr.emoji)
                                        }
                                    }
                                }
                            }
                        }
                        .font(.caption)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                    }
                }
                
                // Done button
                Button {
                    viewModel.resetDecoding(with: decodingDetector)
                } label: {
                    Text("Done")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .cornerRadius(12)
                }
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
    
    private var incorrectSequenceView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Error icon
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.red)
                
                Text("Incorrect Sequence")
                    .font(.title)
                    .fontWeight(.bold)
                
                // Error message
                if let error = viewModel.attemptError {
                    Text(error)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                }
                
                Spacer()
                
                // Action buttons
                VStack(spacing: 12) {
                    Button {
                        viewModel.retryDecoding(with: decodingDetector)
                    } label: {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Try Again")
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .cornerRadius(12)
                    }
                    
                    Button {
                        viewModel.resetDecoding(with: decodingDetector)
                    } label: {
                        Text("Cancel")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .foregroundStyle(.primary)
                            .cornerRadius(12)
                    }
                }
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

#Preview {
    DecodeView()
}
