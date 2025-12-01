//
//  GIFTestView.swift
//  arface-encrypter
//
//  Created by Claude Code
//
//  TEMPORARY TEST VIEW - Will be removed in Phase 6
//

import SwiftUI

struct GIFTestView: View {
    @StateObject private var detector = ARFaceDetector()
    @State private var recorder = ExpressionRecorder()
    @State private var userSettings = UserSettings()

    @State private var generatedGIFURL: URL?
    @State private var isGenerating = false
    @State private var errorMessage: String?
    @State private var extractedMessageID: String?

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                if recorder.isComplete {
                    completedView
                } else {
                    recordingView
                }
            }
            .padding()
            .navigationTitle("GIF Test")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .onChange(of: detector.currentExpression) { _, newExpression in
                if let expression = newExpression, recorder.isRecording {
                    if recorder.recordExpression(expression) {
                        // Haptic feedback
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()

                        // Reset detector's current expression to allow re-detection
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            detector.currentExpression = nil
                        }
                    }
                }
            }
            .onAppear {
                recorder.startRecording()
                detector.startTracking()
            }
            .onDisappear {
                detector.stopTracking()
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                if let error = errorMessage {
                    Text(error)
                }
            }
        }
    }

    // MARK: - Recording View

    private var recordingView: some View {
        VStack(spacing: 20) {
            Text("Record 5 Expressions")
                .font(.title2)
                .fontWeight(.bold)

            // Progress
            VStack(spacing: 12) {
                Text("Expression \(recorder.currentStep + 1) of 5")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                ProgressView(value: recorder.progress)
                    .progressViewStyle(.linear)
                    .tint(.blue)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Recorded expressions - FIXED LAYOUT
            HStack(spacing: 8) {
                ForEach(0..<5, id: \.self) { index in
                    if index < recorder.recordedExpressions.count {
                        VStack(spacing: 4) {
                            ExpressionEmojiView(expression: recorder.recordedExpressions[index])
                                .font(.system(size: 40))
                            Text(recorder.recordedExpressions[index].displayName)
                                .font(.caption2)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                                .foregroundStyle(.secondary)
                        }
                        .frame(width: 60, height: 80)
                        .padding(6)
                        .background(Color.green.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .transition(.scale.combined(with: .opacity))
                    } else {
                        Circle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 40, height: 40)
                            .frame(width: 60, height: 80)
                            .padding(6)
                    }
                }
            }
            .animation(.spring(response: 0.3), value: recorder.recordedExpressions.count)

            // Camera View - MADE TALLER
            ARFaceTrackingView(
                detector: detector,
                showDebugOverlay: false
            )
            .frame(height: 350)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.blue, lineWidth: 2)
            )

            // Instructions
            VStack(spacing: 8) {
                Image(systemName: "info.circle")
                    .foregroundStyle(.blue)
                Text("Perform each expression and hold for 0.5 seconds")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()
        }
    }

    // MARK: - Completed View

    private var completedView: some View {
        VStack(spacing: 20) {
            if isGenerating {
                generatingView
            } else if let gifURL = generatedGIFURL {
                resultView(gifURL: gifURL)
            } else {
                readyToGenerateView
            }
        }
    }

    private var readyToGenerateView: some View {
        VStack(spacing: 20) {
            Text("Sequence Complete! 🎉")
                .font(.title)
                .fontWeight(.bold)

            // SMALLER TEXT
            VStack(spacing: 8) {
                Text("Recorded:")
                    .font(.body)
                    .foregroundStyle(.secondary)

                HStack(spacing: 4) {
                    ForEach(recorder.recordedExpressions, id: \.rawValue) { expression in
                        ExpressionEmojiView(expression: expression)
                            .font(.system(size: 32))
                    }
                }
            }

            Text(recorder.getExpressionHash())
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding()
                .background(Color.gray.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            Spacer()

            Button {
                Task {
                    await generateGIF()
                }
            } label: {
                Label("Generate GIF", systemImage: "photo.stack.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.borderedProminent)

            Button("Reset") {
                reset()
            }
            .buttonStyle(.bordered)
        }
    }

    private var generatingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Generating GIF...")
                .font(.headline)
            Text("This may take a few seconds")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func resultView(gifURL: URL) -> some View {
        VStack(spacing: 20) {
            Text("GIF Generated! ✨")
                .font(.title2)
                .fontWeight(.bold)

            AnimatedGIFView(url: gifURL)
                .frame(height: 300)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )

            if let messageID = extractedMessageID {
                VStack(spacing: 4) {
                    Text("Message ID: \(messageID)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("(Extracted from GIF)")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                .padding(8)
                .background(Color.green.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            ShareLink(item: gifURL, preview: SharePreview("ARFace GIF", image: Image(systemName: "gift.fill"))) {
                Label("Share GIF", systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            Button("Create Another") {
                reset()
            }
            .buttonStyle(.bordered)

            Spacer()
        }
    }

    // MARK: - Actions

    private func generateGIF() async {
        isGenerating = true
        errorMessage = nil

        do {
            let testMessageID = String(Int.random(in: 1000...9999))

            let gifURL = try await GIFGenerator.generateGIF(
                expressions: recorder.recordedExpressions,
                avatar: userSettings.selectedAvatar,
                messageID: testMessageID
            )

            generatedGIFURL = gifURL

            // Test extraction
            if let extracted = await MessageIDExtractor.extractMessageID(from: gifURL) {
                extractedMessageID = extracted
            }

            // Haptic success feedback
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)

        } catch {
            errorMessage = error.localizedDescription

            // Haptic error feedback
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
        }

        isGenerating = false
    }

    private func reset() {
        // Stop tracking first
        detector.stopTracking()

        // Reset state
        recorder.reset()
        generatedGIFURL = nil
        extractedMessageID = nil
        errorMessage = nil

        // Restart recording and tracking
        recorder.startRecording()

        // Give a brief delay before restarting tracking to ensure clean state
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            detector.startTracking()
        }
    }
}

// MARK: - Helper View for Flippable Emojis

/// Displays an emoji with optional horizontal flip for right wink
struct ExpressionEmojiView: View {
    let expression: FaceExpression

    var body: some View {
        Text(expression.emoji)
            .scaleEffect(x: expression.shouldFlipEmoji ? -1 : 1, y: 1)
    }
}

#Preview {
    GIFTestView()
}
