//
//  AvatarType.swift
//  arface-encrypter
//
//  Created by Claude Code
//

import Foundation

enum AvatarType: String, CaseIterable, Codable {
    case bear = "bear"
    case fox = "fox"

    var displayName: String {
        rawValue.capitalized
    }

    var spriteSheetName: String {
        "\(rawValue)-sprite"
    }

    /// Sprite sheet dimensions
    static let spriteSheetSize = CGSize(width: 768, height: 512)
    static let gridColumns = 3
    static let gridRows = 2
    static let spriteSize = CGSize(width: 256, height: 256)
}
