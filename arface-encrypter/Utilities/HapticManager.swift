//
//  HapticManager.swift
//  arface-encrypter
//
//  Created by Claude Code
//

import UIKit

/// Provides haptic feedback for various app interactions
class HapticManager {
    
    /// Haptic feedback when an expression is detected and recorded
    static func expressionDetected() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
        print("📳 Haptic: expression detected")
    }
    
    /// Haptic feedback when the full expression sequence is complete
    static func sequenceComplete() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
        print("📳 Haptic: sequence complete (success)")
    }
    
    /// Haptic feedback for errors
    static func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.error)
        print("📳 Haptic: error")
    }
    
    /// Light haptic feedback for button taps
    static func lightTap() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
    }
    
    /// Heavy haptic feedback for important actions
    static func heavyTap() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.prepare()
        generator.impactOccurred()
    }
}

