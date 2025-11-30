//
//  FaceDetectionThresholds.swift
//  arface-encrypter
//
//  Created by Claude Code
//

import Foundation

/// Thresholds for ARKit face detection
/// These values are tuned for reliable expression detection
/// Adjust these during Phase 2 based on real-world testing
struct FaceDetectionThresholds {
    // MARK: - Wink Detection
    static let winkEyeClosed: Float = 0.8
    static let winkEyeOpen: Float = 0.3

    // MARK: - Tongue Out
    static let tongueOut: Float = 0.3

    // MARK: - Surprise
    static let jawOpen: Float = 0.5
    static let browUp: Float = 0.5

    // MARK: - Smile
    static let mouthSmile: Float = 0.6

    // MARK: - Smooch
    static let mouthPucker: Float = 0.5
    static let cheekPuff: Float = 0.5

    // MARK: - Neutral Detection
    static let neutralThreshold: Float = 0.3

    // MARK: - Timing
    /// How long an expression must be held before it triggers
    static let expressionHoldDuration: TimeInterval = 0.4

    /// How long to wait after detecting an expression before accepting the next one
    static let expressionCooldown: TimeInterval = 0.2
}
