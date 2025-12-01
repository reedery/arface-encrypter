//
//  ExpressionRecorder.swift
//  arface-encrypter
//
//  Created by Claude Code
//

import Foundation
import Observation

/// Records a sequence of facial expressions
/// Ensures expressions are unique and prevents rapid duplicates
@Observable
class ExpressionRecorder {

    // MARK: - Published Properties

    var recordedExpressions: [FaceExpression] = []
    var isRecording: Bool = false

    // MARK: - Computed Properties

    var currentStep: Int {
        recordedExpressions.count
    }

    var isComplete: Bool {
        recordedExpressions.count >= 5
    }

    var progress: Double {
        Double(recordedExpressions.count) / 5.0
    }

    // MARK: - Public Methods

    /// Start recording expressions
    func startRecording() {
        isRecording = true
        recordedExpressions.removeAll()
        print("🎬 Expression recording started")
    }

    /// Record an expression
    /// Returns true if expression was recorded, false if duplicate or not recording
    func recordExpression(_ expression: FaceExpression) -> Bool {
        guard isRecording else {
            print("⚠️ Not recording - ignoring expression")
            return false
        }

        guard !isComplete else {
            print("⚠️ Recording complete - ignoring expression")
            return false
        }

        // Prevent duplicate consecutive expressions
        if let lastExpression = recordedExpressions.last, lastExpression == expression {
            print("⚠️ Duplicate expression - ignoring \(expression.displayName)")
            return false
        }

        // Record the expression
        recordedExpressions.append(expression)
        print("✅ Recorded expression \(recordedExpressions.count)/5: \(expression.displayName) \(expression.emoji)")

        // Check if recording is complete
        if isComplete {
            isRecording = false
            print("🎉 Recording complete! Sequence: \(getExpressionHash())")
        }

        return true
    }

    /// Reset recording
    func reset() {
        recordedExpressions.removeAll()
        isRecording = false
        print("🔄 Expression recording reset")
    }

    /// Get expression hash (comma-separated expression IDs)
    /// Format: "wink_l,tongue_out,surprise,smile,smooch"
    func getExpressionHash() -> String {
        recordedExpressions.map(\.rawValue).joined(separator: ",")
    }

    /// Get expression list for display (emoji string)
    func getExpressionEmojis() -> String {
        recordedExpressions.map(\.emoji).joined()
    }
}
