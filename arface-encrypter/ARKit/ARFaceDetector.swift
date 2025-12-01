//
//  ARFaceDetector.swift
//  arface-encrypter
//
//  Created by Claude Code
//

import Foundation
import ARKit
import Combine

/// Detects facial expressions using ARKit face tracking
/// Publishes detected expressions and provides real-time blendshape data
///
/// Usage:
/// ```swift
/// let detector = ARFaceDetector()
/// detector.startTracking()
/// // Observe detector.currentExpression for changes
/// detector.stopTracking()
/// ```
@MainActor
class ARFaceDetector: NSObject, ObservableObject {

    // MARK: - Published Properties

    /// Currently detected expression (only published after hold duration)
    @Published var currentExpression: FaceExpression?

    /// Whether the face is in a neutral state (all blendshapes below threshold)
    @Published var isNeutral: Bool = true

    /// Whether face tracking is currently active
    @Published var detectionActive: Bool = false

    /// Debug blendshapes for tuning thresholds
    @Published var debugBlendshapes: [String: Float] = [:]

    // MARK: - Private Properties

    let session = ARSession()
    private var expressionStartTime: Date?
    private var lastDetectedExpression: FaceExpression?
    private var lastExpressionTriggerTime: Date?

    // MARK: - Lifecycle

    override init() {
        super.init()
        session.delegate = self
    }
    
    deinit {
        session.pause()
    }

    /// Start ARKit face tracking
    func startTracking() {
        guard ARFaceTrackingConfiguration.isSupported else {
            print("⚠️ ARKit face tracking not supported on this device")
            return
        }

        let configuration = ARFaceTrackingConfiguration()
        configuration.isLightEstimationEnabled = true

        session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        detectionActive = true
        print("✅ ARKit face tracking started")
    }

    /// Stop ARKit face tracking
    func stopTracking() {
        session.pause()
        detectionActive = false
        currentExpression = nil
        isNeutral = true
        expressionStartTime = nil
        lastDetectedExpression = nil
        print("⏸️ ARKit face tracking stopped")
    }

    // MARK: - Expression Detection Logic

    /// Detect expression from ARKit blendshapes
    /// Priority order (most specific first):
    /// 1. tongueOut
    /// 2. winkLeft / winkRight
    /// 3. smooch
    /// 4. surprise
    /// 5. smile
    private func detectExpression(from blendshapes: [ARFaceAnchor.BlendShapeLocation: NSNumber]) -> FaceExpression? {

        // Helper to get blendshape value
        func value(_ location: ARFaceAnchor.BlendShapeLocation) -> Float {
            blendshapes[location]?.floatValue ?? 0.0
        }

        // 1. Tongue Out (highest priority - most unique)
        if value(.tongueOut) > FaceDetectionThresholds.tongueOut {
            return .tongueOut
        }

        // 2. Left Wink (left eye closed, right eye open)
        if value(.eyeBlinkLeft) > FaceDetectionThresholds.winkEyeClosed &&
           value(.eyeBlinkRight) < FaceDetectionThresholds.winkEyeOpen {
            return .winkLeft
        }

        // 3. Right Wink (right eye closed, left eye open)
        if value(.eyeBlinkRight) > FaceDetectionThresholds.winkEyeClosed &&
           value(.eyeBlinkLeft) < FaceDetectionThresholds.winkEyeOpen {
            return .winkRight
        }

        // 4. Smooch/Pucker (lips pursed)
        if value(.mouthPucker) > FaceDetectionThresholds.mouthPucker ||
           value(.cheekPuff) > FaceDetectionThresholds.cheekPuff {
            return .smooch
        }

        // 5. Surprise (jaw open + eyebrows raised)
        if value(.jawOpen) > FaceDetectionThresholds.jawOpen &&
           value(.browInnerUp) > FaceDetectionThresholds.browUp {
            return .surprise
        }

        // 6. Smile (both mouth corners up)
        if value(.mouthSmileLeft) > FaceDetectionThresholds.mouthSmile &&
           value(.mouthSmileRight) > FaceDetectionThresholds.mouthSmile {
            return .smile
        }

        return nil
    }

    /// Check if face is in neutral state (all relevant blendshapes below threshold)
    private func isNeutralFace(blendshapes: [ARFaceAnchor.BlendShapeLocation: NSNumber]) -> Bool {
        func value(_ location: ARFaceAnchor.BlendShapeLocation) -> Float {
            blendshapes[location]?.floatValue ?? 0.0
        }

        let threshold = FaceDetectionThresholds.neutralThreshold

        return value(.eyeBlinkLeft) < threshold &&
               value(.eyeBlinkRight) < threshold &&
               value(.tongueOut) < threshold &&
               value(.jawOpen) < threshold &&
               value(.browInnerUp) < threshold &&
               value(.mouthSmileLeft) < threshold &&
               value(.mouthSmileRight) < threshold &&
               value(.mouthPucker) < threshold &&
               value(.cheekPuff) < threshold
    }

    /// Process blendshapes and update published properties
    private func processBlendshapes(_ blendshapes: [ARFaceAnchor.BlendShapeLocation: NSNumber]) {

        // Update debug blendshapes
        var debugDict: [String: Float] = [:]
        for (location, value) in blendshapes {
            debugDict[location.rawValue] = value.floatValue
        }
        debugBlendshapes = debugDict

        // Check if neutral
        let neutral = isNeutralFace(blendshapes: blendshapes)
        isNeutral = neutral

        // If neutral, reset tracking
        if neutral {
            if expressionStartTime != nil {
                expressionStartTime = nil
                lastDetectedExpression = nil
            }
            return
        }

        // Detect current expression
        guard let detectedExpression = detectExpression(from: blendshapes) else {
            expressionStartTime = nil
            lastDetectedExpression = nil
            return
        }

        let now = Date()

        // If this is a new expression, start tracking it
        if detectedExpression != lastDetectedExpression {
            expressionStartTime = now
            lastDetectedExpression = detectedExpression
            return
        }

        // Check if expression has been held long enough
        guard let startTime = expressionStartTime else { return }
        let holdDuration = now.timeIntervalSince(startTime)

        if holdDuration >= FaceDetectionThresholds.expressionHoldDuration {
            // Check cooldown period
            if let lastTrigger = lastExpressionTriggerTime {
                let timeSinceLastTrigger = now.timeIntervalSince(lastTrigger)
                if timeSinceLastTrigger < FaceDetectionThresholds.expressionCooldown {
                    return // Still in cooldown
                }
            }

            // Expression detected and held long enough!
            currentExpression = detectedExpression
            lastExpressionTriggerTime = now

            print("✅ Expression detected: \(detectedExpression.displayName) \(detectedExpression.emoji)")
        }
    }
}

// MARK: - ARSessionDelegate

extension ARFaceDetector: ARSessionDelegate {

    nonisolated func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        guard let faceAnchor = anchors.compactMap({ $0 as? ARFaceAnchor }).first else {
            return
        }

        let blendshapes = faceAnchor.blendShapes

        Task { @MainActor in
            processBlendshapes(blendshapes)
        }
    }

    nonisolated func session(_ session: ARSession, didFailWithError error: Error) {
        print("⚠️ ARSession failed: \(error.localizedDescription)")
    }

    nonisolated func sessionWasInterrupted(_ session: ARSession) {
        print("⚠️ ARSession was interrupted")
    }

    nonisolated func sessionInterruptionEnded(_ session: ARSession) {
        print("✅ ARSession interruption ended")
    }
}
