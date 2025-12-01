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
            VStack(spacing: 16) {
                Image(systemName: "lock.open.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.teal)
                    .padding(.bottom, 8)
                
                Text("Unlock a Secret Message")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Recreate the facial expression sequence to reveal the hidden message")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                
                // How it works section
                VStack(spacing: 16) {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.teal.opacity(0.15))
                                .frame(width: 40, height: 40)
                            Text("1")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundStyle(.teal)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Load the encrypted GIF")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Text("Select from your photos")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.teal.opacity(0.15))
                                .frame(width: 40, height: 40)
                            Text("2")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundStyle(.teal)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Match the expressions")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Text("Use your face to recreate each one")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.teal.opacity(0.15))
                                .frame(width: 40, height: 40)
                            Text("3")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundStyle(.teal)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Unlock the message")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Text("Read the secret message!")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                }
                .padding(20)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(16)
                .padding(.horizontal, 24)
                .padding(.top, 8)
            }
            .padding(.top, 60)
            .padding(.bottom, 30)
            
            Button {
                viewModel.startDecoding(with: decodingDetector)
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "faceid")
                        .font(.system(size: 24, weight: .semibold))
                    Text("Start Unlocking")
                        .font(.headline)
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
            .overlay(alignment: .top) {
                // Top center: Instructions and status
                VStack(spacing: 12) {
                    // Progress indicator
                    HStack(spacing: 8) {
                        Image(systemName: "lock.open")
                            .font(.system(size: 14))
                        Text("Expression \(viewModel.decodingRecorder.currentStep + 1) of 5")
                            .font(.headline)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial)
                    .cornerRadius(20)
                    
                    // Current expression detected
                    if let currentExpr = decodingDetector.currentExpression {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 16))
                            Text("\(currentExpr.emoji) \(currentExpr.displayName)")
                                .font(.title3)
                                .fontWeight(.semibold)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(.teal)
                        .foregroundStyle(.white)
                        .cornerRadius(20)
                        .shadow(color: .teal.opacity(0.4), radius: 8)
                    } else {
                        // Helpful instructions
                        HStack(spacing: 8) {
                            Image(systemName: decodingDetector.detectionActive ? "face.smiling" : "exclamationmark.triangle")
                                .font(.system(size: 14))
                            Text(decodingDetector.isNeutral ? "Match the expressions in the GIF" : "Hold your expression...")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial)
                        .foregroundStyle(decodingDetector.detectionActive ? .primary : Color.orange)
                        .cornerRadius(20)
                    }
                }
                .padding()
            }
            .overlay(alignment: .bottomTrailing) {
                // Bottom right: Small GIF preview or load button
                VStack(spacing: 4) {
                    if let gifURL = viewModel.selectedGIFURL {
                        VStack(spacing: 4) {
                            Text("Reference")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.teal)
                                .cornerRadius(6)
                            
                            // Show small GIF preview
                            AnimatedGIFView(url: gifURL)
                                .frame(width: 100, height: 100)
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.teal, lineWidth: 2)
                                )
                                .shadow(color: .black.opacity(0.3), radius: 6)
                        }
                    } else {
                        // Load GIF button with icon
                        Button {
                            showingImagePicker = true
                        } label: {
                            VStack(spacing: 6) {
                                Image(systemName: "photo.badge.plus")
                                    .font(.system(size: 28))
                                    .foregroundStyle(.teal)
                                Text("Load GIF")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(.primary)
                            }
                            .frame(width: 100, height: 100)
                            .background(.ultraThinMaterial)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.teal.opacity(0.5), style: StrokeStyle(lineWidth: 2, dash: [5, 3]))
                            )
                            .shadow(color: .black.opacity(0.2), radius: 4)
                        }
                    }
                }
                .padding()
            }
            .overlay(alignment: .center) {
                // Face detection guide circle
                if !decodingDetector.detectionActive || decodingDetector.isNeutral {
                    VStack(spacing: 16) {
                        Circle()
                            .stroke(
                                decodingDetector.detectionActive ? Color.teal.opacity(0.5) : Color.orange.opacity(0.5),
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
            
            // Bottom section: Progress
            VStack(spacing: 16) {
                // Helpful tip banner
                HStack(spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(.teal)
                    Text("Watch the reference GIF and match each expression")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.teal.opacity(0.1))
                .cornerRadius(10)
                
                // Expression sequence progress
                HStack(spacing: 12) {
                    ForEach(0..<5, id: \.self) { index in
                        if index < viewModel.decodingRecorder.recordedExpressions.count {
                            // Recorded expression with checkmark
                            VStack(spacing: 4) {
                                Text(viewModel.decodingRecorder.recordedExpressions[index].emoji)
                                    .font(.system(size: 36))
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 14))
                                    .foregroundStyle(.green)
                            }
                            .padding(8)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.green.opacity(0.3), lineWidth: 2)
                            )
                            .transition(.scale.combined(with: .opacity))
                        } else if index == viewModel.decodingRecorder.currentStep {
                            // Current step indicator
                            VStack(spacing: 4) {
                                Circle()
                                    .fill(Color.teal.opacity(0.2))
                                    .frame(width: 40, height: 40)
                                    .overlay {
                                        Image(systemName: "arrow.right.circle")
                                            .font(.system(size: 28))
                                            .foregroundStyle(.teal)
                                    }
                                Text("Now")
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.teal)
                            }
                            .padding(8)
                            .background(Color.teal.opacity(0.15))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.teal, lineWidth: 2)
                            )
                        } else {
                            // Empty placeholder for upcoming expressions
                            VStack(spacing: 4) {
                                Circle()
                                    .fill(Color.gray.opacity(0.1))
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Text("\(index + 1)")
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundStyle(.secondary)
                                    )
                                Text("Next")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(8)
                        }
                    }
                }
                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: viewModel.decodingRecorder.recordedExpressions.count)
                
                // Instruction text
                HStack(spacing: 6) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 12))
                    Text("Return to neutral between expressions")
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
            }
            .padding()
            .background(.ultraThinMaterial)
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
        VStack(spacing: 30) {
            Spacer()
            
            // Animated icon
            ZStack {
                Circle()
                    .fill(Color.teal.opacity(0.1))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "lock.trianglebadge.exclamationmark")
                    .font(.system(size: 50))
                    .foregroundStyle(.teal)
            }
            
            ProgressView()
                .scaleEffect(1.2)
            
            VStack(spacing: 8) {
                Text("Validating Sequence...")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.shield")
                        .font(.caption)
                    Text("Checking if your expressions match")
                        .font(.subheadline)
                }
                .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
    
    private var messageRevealedView: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer()
                
                // Success icon with animation
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.1))
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "lock.open.fill")
                        .font(.system(size: 70))
                        .foregroundStyle(.green)
                }
                .transition(.scale.combined(with: .opacity))
                
                VStack(spacing: 8) {
                    Text("Message Unlocked! 🎉")
                        .font(.title)
                        .fontWeight(.bold)
                        .transition(.opacity)
                    
                    Text("You successfully matched the sequence!")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Decoded message
                if let message = viewModel.decodedMessage {
                    VStack(spacing: 16) {
                        // Secret message label
                        HStack(spacing: 6) {
                            Image(systemName: "envelope.open.fill")
                                .font(.caption)
                                .foregroundStyle(.green)
                            Text("Secret Message")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(20)
                        
                        // The actual message
                        Text(message.message ?? "")
                            .font(.title3)
                            .fontWeight(.medium)
                            .multilineTextAlignment(.center)
                            .padding(24)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.green.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.green, lineWidth: 2)
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
                Spacer()
                
                // Error icon
                ZStack {
                    Circle()
                        .fill(Color.red.opacity(0.1))
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "xmark.shield.fill")
                        .font(.system(size: 70))
                        .foregroundStyle(.red)
                }
                
                VStack(spacing: 8) {
                    Text("Unlock Failed")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("The expression sequence didn't match")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                // Error message with helpful tips
                VStack(spacing: 16) {
                    if let error = viewModel.attemptError {
                        Text(error)
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(12)
                    }
                    
                    // Tips section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: "lightbulb.fill")
                                .foregroundStyle(.orange)
                            Text("Tips for success:")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle")
                                    .font(.caption)
                                    .foregroundStyle(.green)
                                Text("Watch the reference GIF carefully")
                                    .font(.caption)
                            }
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle")
                                    .font(.caption)
                                    .foregroundStyle(.green)
                                Text("Hold each expression for 1 second")
                                    .font(.caption)
                            }
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle")
                                    .font(.caption)
                                    .foregroundStyle(.green)
                                Text("Return to neutral between expressions")
                                    .font(.caption)
                            }
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle")
                                    .font(.caption)
                                    .foregroundStyle(.green)
                                Text("Make sure your face is clearly visible")
                                    .font(.caption)
                            }
                        }
                        .foregroundStyle(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                }
                
                Spacer()
                
                // Action buttons
                VStack(spacing: 12) {
                    Button {
                        viewModel.retryDecoding(with: decodingDetector)
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.clockwise.circle.fill")
                                .font(.system(size: 20))
                            Text("Try Again")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [Color.teal, Color.teal.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundStyle(.white)
                        .cornerRadius(16)
                        .shadow(color: .teal.opacity(0.3), radius: 6)
                    }
                    
                    Button {
                        viewModel.resetDecoding(with: decodingDetector)
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "xmark.circle")
                            Text("Cancel")
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(.secondarySystemBackground))
                        .foregroundStyle(.primary)
                        .cornerRadius(16)
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
