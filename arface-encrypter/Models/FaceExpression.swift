//
//  FaceExpression.swift
//  arface-encrypter
//
//  Created by Claude Code
//

import Foundation

enum FaceExpression: String, CaseIterable, Codable {
    case winkLeft = "wink_l"
    case winkRight = "wink_r"
    case tongueOut = "tongue_out"
    case surprise = "surprise"
    case smile = "smile"
    case smooch = "smooch"

    var displayName: String {
        switch self {
        case .winkLeft:
            return "Left Wink"
        case .winkRight:
            return "Right Wink"
        case .tongueOut:
            return "Tongue Out"
        case .surprise:
            return "Surprise"
        case .smile:
            return "Smile"
        case .smooch:
            return "Smooch"
        }
    }

    var emoji: String {
        switch self {
        case .winkLeft:
            return "😉"
        case .winkRight:
            return "😉"  // Same as left wink, will be flipped in UI
        case .tongueOut:
            return "😛"
        case .surprise:
            return "😮"
        case .smile:
            return "😁"
        case .smooch:
            return "😘"
        }
    }

    /// Whether this emoji should be flipped horizontally in the UI
    var shouldFlipEmoji: Bool {
        switch self {
        case .winkRight:
            return true
        default:
            return false
        }
    }

    /// Grid position in sprite sheet (row, column) - 0-indexed
    /// Sprite sheet is 3 columns × 2 rows
    var gridPosition: (row: Int, column: Int) {
        switch self {
        case .winkLeft:
            return (0, 0)  // Top-left
        case .tongueOut:
            return (0, 1)  // Top-middle
        case .surprise:
            return (0, 2)  // Top-right
        case .winkRight:
            return (1, 0)  // Bottom-left
        case .smile:
            return (1, 1)  // Bottom-middle
        case .smooch:
            return (1, 2)  // Bottom-right
        }
    }
}
