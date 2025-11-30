//
//  SpriteSheetExtractor.swift
//  arface-encrypter
//
//  Created by Claude Code
//

import UIKit

/// Extracts individual sprite images from sprite sheets
/// Sprite sheets are 768×512px grids (3 columns × 2 rows)
/// Each sprite is 256×256px
class SpriteSheetExtractor {

    /// Extract a single sprite for a specific expression from a sprite sheet
    /// - Parameters:
    ///   - spriteSheet: The full sprite sheet image
    ///   - expression: The expression to extract
    /// - Returns: The extracted sprite image, or nil if extraction fails
    static func extractSprite(from spriteSheet: UIImage, expression: FaceExpression) -> UIImage? {
        guard let cgImage = spriteSheet.cgImage else { return nil }

        let position = expression.gridPosition
        let spriteWidth = AvatarType.spriteSize.width
        let spriteHeight = AvatarType.spriteSize.height

        // Calculate the rect to crop
        let x = CGFloat(position.column) * spriteWidth
        let y = CGFloat(position.row) * spriteHeight
        let rect = CGRect(x: x, y: y, width: spriteWidth, height: spriteHeight)

        // Crop the sprite
        guard let croppedCGImage = cgImage.cropping(to: rect) else { return nil }

        return UIImage(cgImage: croppedCGImage, scale: spriteSheet.scale, orientation: spriteSheet.imageOrientation)
    }

    /// Extract all sprites from a sprite sheet for a given avatar
    /// - Parameter avatar: The avatar type (bear or fox)
    /// - Returns: Dictionary mapping expressions to their sprite images
    static func extractAllSprites(from avatar: AvatarType) -> [FaceExpression: UIImage] {
        guard let spriteSheet = UIImage(named: avatar.spriteSheetName) else {
            print("⚠️ Could not load sprite sheet: \(avatar.spriteSheetName)")
            return [:]
        }

        var sprites: [FaceExpression: UIImage] = [:]

        for expression in FaceExpression.allCases {
            if let sprite = extractSprite(from: spriteSheet, expression: expression) {
                sprites[expression] = sprite
            } else {
                print("⚠️ Failed to extract sprite for \(expression.rawValue)")
            }
        }

        return sprites
    }

    /// Get a specific sprite for an avatar and expression
    /// - Parameters:
    ///   - avatar: The avatar type
    ///   - expression: The expression
    /// - Returns: The sprite image, or nil if not found
    static func getSprite(for avatar: AvatarType, expression: FaceExpression) -> UIImage? {
        guard let spriteSheet = UIImage(named: avatar.spriteSheetName) else {
            print("⚠️ Could not load sprite sheet: \(avatar.spriteSheetName)")
            return nil
        }

        return extractSprite(from: spriteSheet, expression: expression)
    }
}
