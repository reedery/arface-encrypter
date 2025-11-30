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

                            // Filter to show only relevant blendshapes
                            let relevantKeys = [
                                "eyeBlinkLeft", "eyeBlinkRight",
                                "tongueOut",
                                "jawOpen", "browInnerUp",
                                "mouthSmileLeft", "mouthSmileRight",
                                "mouthPucker", "cheekPuff"
                            ]

                            ForEach(relevantKeys.sorted(), id: \.self) { key in
                                if let value = detector.debugBlendshapes[key] {
                                    HStack {
                                        Text(key)
                                            .font(.caption)
                                            .frame(maxWidth: .infinity, alignment: .leading)

                                        Text(String(format: "%.2f", value))
                                            .font(.caption.monospacedDigit())
                                            .foregroundColor(value > 0.5 ? .green : .primary)
                                            .frame(width: 50, alignment: .trailing)

                                        // Visual bar
                                        GeometryReader { geo in
                                            HStack(spacing: 0) {
                                                Rectangle()
                                                    .fill(Color.green)
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
            .toolbar {
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
