//
//  GIFGenerator.swift
//  arface-encrypter
//
//  Created by Claude Code
//

import UIKit
import ImageIO
import UniformTypeIdentifiers

/// Generates animated GIFs from facial expression sequences
class GIFGenerator {

    enum GIFError: LocalizedError {
        case invalidSprite
        case missingSprites
        case failedToCreateGIF
        case failedToWriteFile

        var errorDescription: String? {
            switch self {
            case .invalidSprite:
                return "Failed to extract sprite from sprite sheet"
            case .missingSprites:
                return "Some sprites are missing from the sprite sheet"
            case .failedToCreateGIF:
                return "Failed to create GIF image"
            case .failedToWriteFile:
                return "Failed to write GIF file to disk"
            }
        }
    }

    /// Generate animated GIF from expression sequence
    /// - Parameters:
    ///   - expressions: Array of 5 facial expressions
    ///   - avatar: Avatar type (bear or fox)
    ///   - messageID: Message ID to overlay on last frame
    /// - Returns: URL to generated GIF file in temp directory
    static func generateGIF(
        expressions: [FaceExpression],
        avatar: AvatarType,
        messageID: String
    ) async throws -> URL {

        print("🎬 Starting GIF generation...")
        print("   Expressions: \(expressions.map(\.rawValue).joined(separator: ", "))")
        print("   Avatar: \(avatar.displayName)")
        print("   Message ID: \(messageID)")

        // 1. Extract all sprites from sprite sheet
        let sprites = SpriteSheetExtractor.extractAllSprites(from: avatar)

        guard sprites.count == FaceExpression.allCases.count else {
            print("⚠️ Missing sprites! Got \(sprites.count), expected \(FaceExpression.allCases.count)")
            throw GIFError.missingSprites
        }

        // 2. Use wink_l as neutral frame between expressions
        guard let neutralSprite = sprites[.winkLeft] else {
            throw GIFError.invalidSprite
        }

        // 3. Build frame sequence
        var frames: [UIImage] = []
        var frameDurations: [TimeInterval] = []

        // Start with neutral
        frames.append(neutralSprite)
        frameDurations.append(0.5)

        // Add each expression with neutral in between
        for expression in expressions {
            guard let expressionSprite = sprites[expression] else {
                print("⚠️ Missing sprite for expression: \(expression.rawValue)")
                throw GIFError.invalidSprite
            }

            // Expression frame
            frames.append(expressionSprite)
            frameDurations.append(0.5)

            // Back to neutral
            frames.append(neutralSprite)
            frameDurations.append(0.3)
        }

        // 4. Add message ID overlay to last frame
        let lastFrameWithID = addTextOverlay(to: frames.last!, text: "ID:\(messageID)")
        frames[frames.count - 1] = lastFrameWithID

        // Extend last frame duration for readability
        frameDurations[frameDurations.count - 1] = 0.5

        print("   Total frames: \(frames.count)")
        print("   Total duration: \(frameDurations.reduce(0, +))s")

        // 5. Generate GIF using ImageIO
        let gifURL = try await createGIF(from: frames, frameDurations: frameDurations, messageID: messageID)

        print("✅ GIF generated successfully at: \(gifURL.path)")
        return gifURL
    }

    /// Create GIF file from image frames
    private static func createGIF(
        from images: [UIImage],
        frameDurations: [TimeInterval],
        messageID: String
    ) async throws -> URL {

        // Create temp file URL
        let tempDirectory = FileManager.default.temporaryDirectory
        let fileName = "arface_\(messageID)_\(UUID().uuidString).gif"
        let fileURL = tempDirectory.appendingPathComponent(fileName)

        // Remove existing file if present
        try? FileManager.default.removeItem(at: fileURL)

        // Create CGImageDestination
        guard let destination = CGImageDestinationCreateWithURL(
            fileURL as CFURL,
            UTType.gif.identifier as CFString,
            images.count,
            nil
        ) else {
            throw GIFError.failedToCreateGIF
        }

        // GIF properties (loop forever)
        let gifProperties: [String: Any] = [
            kCGImagePropertyGIFDictionary as String: [
                kCGImagePropertyGIFLoopCount as String: 0  // 0 = loop forever
            ]
        ]
        CGImageDestinationSetProperties(destination, gifProperties as CFDictionary)

        // Add each frame
        for (index, image) in images.enumerated() {
            guard let cgImage = image.cgImage else { continue }

            let duration = frameDurations[index]

            let frameProperties: [String: Any] = [
                kCGImagePropertyGIFDictionary as String: [
                    kCGImagePropertyGIFDelayTime as String: duration
                ]
            ]

            CGImageDestinationAddImage(destination, cgImage, frameProperties as CFDictionary)
        }

        // Finalize GIF
        guard CGImageDestinationFinalize(destination) else {
            throw GIFError.failedToWriteFile
        }

        return fileURL
    }

    /// Add text overlay to image
    private static func addTextOverlay(to image: UIImage, text: String) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: image.size)

        return renderer.image { context in
            // Draw original image
            image.draw(in: CGRect(origin: .zero, size: image.size))

            // Configure text
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 14),
                .foregroundColor: UIColor.white,
                .strokeColor: UIColor.black,
                .strokeWidth: -3.0  // Negative for fill + stroke
            ]

            let attributedText = NSAttributedString(string: text, attributes: attributes)

            // Calculate text position (top-left corner)
            let textSize = attributedText.size()
            let textRect = CGRect(
                x: 8,
                y: 8,
                width: textSize.width,
                height: textSize.height
            )

            // Draw semi-transparent background
            context.cgContext.setFillColor(UIColor.black.withAlphaComponent(0.5).cgColor)
            context.cgContext.fill(textRect.insetBy(dx: -4, dy: -2))

            // Draw text
            attributedText.draw(in: textRect)
        }
    }
}
