//
//  FaceDetectionTestView.swift
//  arface-encrypter
//
//  Created by Claude Code
//
//  TEMPORARY TEST VIEW - Will be removed in Phase 6
//

import SwiftUI

struct FaceDetectionTestView: View {
    @StateObject private var detector = ARFaceDetector()
    @State private var showDebugOverlay = true
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Camera View
                ZStack {
                    ARFaceTrackingView(
                        detector: detector,
                        showDebugOverlay: showDebugOverlay
                    )

                    // Detection Status Overlay
                    VStack {
                        HStack {
                            Spacer()

                            // Active indicator
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(detector.detectionActive ? Color.green : Color.red)
                                    .frame(width: 10, height: 10)

                                Text(detector.detectionActive ? "Tracking" : "Inactive")
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .padding(8)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .padding()
                        }

                        Spacer()
                    }
                }
                .frame(height: 300)

                // Detected Expression Display
                VStack(spacing: 16) {
                    if let expression = detector.currentExpression {
                        VStack(spacing: 8) {
                            Text(expression.emoji)
                                .font(.system(size: 80))
                                .transition(.scale.combined(with: .opacity))

                            Text(expression.displayName)
                                .font(.title)
                                .fontWeight(.bold)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else {
                        VStack(spacing: 8) {
                            if detector.isNeutral {
                                Text("😐")
                                    .font(.system(size: 60))
                                Text("Neutral")
                                    .font(.headline)
                                    .foregroundStyle(.secondary)
                            } else {
                                ProgressView()
                                    .scaleEffect(1.5)
                                    .padding(.bottom, 4)
                                Text("Hold expression...")
                                    .font(.headline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding()
                .animation(.spring(response: 0.3), value: detector.currentExpression)

                // Debug Blendshape Values
                if showDebugOverlay {
                    Divider()

                    ScrollView {
                        VStack(spacing: 0) {
                            Text("Debug Blendshapes")
                                .font(.headline)
                                .padding(.vertical, 8)

                            // Expanded list of blendshapes for tuning
                            let relevantKeys = [
                                // Eyes
                                "eyeBlinkLeft", "eyeBlinkRight",
                                "eyeLookDownLeft", "eyeLookDownRight",
                                "eyeLookInLeft", "eyeLookInRight",
                                "eyeLookOutLeft", "eyeLookOutRight",
                                "eyeLookUpLeft", "eyeLookUpRight",
                                "eyeSquintLeft", "eyeSquintRight",
                                "eyeWideLeft", "eyeWideRight",
                                // Brows
                                "browDownLeft", "browDownRight",
                                "browInnerUp",
                                "browOuterUpLeft", "browOuterUpRight",
                                // Jaw & Mouth
                                "jawOpen", "jawForward", "jawLeft", "jawRight",
                                "mouthClose",
                                "mouthFunnel", "mouthPucker",
                                "mouthLeft", "mouthRight",
                                "mouthSmileLeft", "mouthSmileRight",
                                "mouthFrownLeft", "mouthFrownRight",
                                "mouthDimpleLeft", "mouthDimpleRight",
                                "mouthStretchLeft", "mouthStretchRight",
                                "mouthRollLower", "mouthRollUpper",
                                "mouthShrugLower", "mouthShrugUpper",
                                "mouthPressLeft", "mouthPressRight",
                                "mouthLowerDownLeft", "mouthLowerDownRight",
                                "mouthUpperUpLeft", "mouthUpperUpRight",
                                // Cheeks & Nose
                                "cheekPuff",
                                "cheekSquintLeft", "cheekSquintRight",
                                "noseSneerLeft", "noseSneerRight",
                                // Tongue
                                "tongueOut"
                            ]

                            ForEach(relevantKeys.sorted(), id: \.self) { key in
                                if let value = detector.debugBlendshapes[key] {
                                    HStack {
                                        Text(key)
                                            .font(.caption)
                                            .frame(maxWidth: .infinity, alignment: .leading)

                                        Text(String(format: "%.3f", value))
                                            .font(.caption.monospacedDigit())
                                            .foregroundColor(value > 0.5 ? .green : (value > 0.3 ? .orange : .primary))
                                            .frame(width: 55, alignment: .trailing)

                                        // Visual bar
                                        GeometryReader { geo in
                                            HStack(spacing: 0) {
                                                Rectangle()
                                                    .fill(value > 0.5 ? Color.green : (value > 0.3 ? Color.orange : Color.blue))
                                                    .frame(width: geo.size.width * CGFloat(min(value, 1.0)))
                                                Spacer(minLength: 0)
                                            }
                                        }
                                        .frame(height: 8)
                                        .background(Color.gray.opacity(0.2))
                                        .clipShape(RoundedRectangle(cornerRadius: 4))
                                        .frame(width: 100)
                                    }
                                    .padding(.horizontal)
                                    .padding(.vertical, 4)
                                }
                            }
                        }
                    }
                    .frame(maxHeight: 300)
                }

                Spacer()
            }
            .navigationTitle("Face Detection Test")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showDebugOverlay.toggle()
                    } label: {
                        Image(systemName: showDebugOverlay ? "eye.fill" : "eye.slash.fill")
                    }
                }
            }
            .onAppear {
                detector.startTracking()
            }
            .onDisappear {
                detector.stopTracking()
            }
        }
    }
}

#Preview {
    FaceDetectionTestView()
}
