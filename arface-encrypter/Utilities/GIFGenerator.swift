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

    /// Clean up old GIF files from temp directory
    static func cleanupOldGIFs() {
        let tempDirectory = FileManager.default.temporaryDirectory
        let fileManager = FileManager.default
        
        do {
            let contents = try fileManager.contentsOfDirectory(
                at: tempDirectory,
                includingPropertiesForKeys: [.creationDateKey],
                options: [.skipsHiddenFiles]
            )
            
            // Filter for arface GIF files
            let arfaceGIFs = contents.filter { $0.lastPathComponent.hasPrefix("arface_") && $0.pathExtension == "gif" }
            
            // Remove all old arface GIF files
            for gifURL in arfaceGIFs {
                try? fileManager.removeItem(at: gifURL)
            }
            
            if !arfaceGIFs.isEmpty {
                print("🧹 Cleaned up \(arfaceGIFs.count) old GIF file(s)")
            }
        } catch {
            print("⚠️ Failed to cleanup old GIFs: \(error.localizedDescription)")
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

        // Clean up old GIF files before generating new one
        cleanupOldGIFs()

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

        // 2. Build frame sequence - just the 5 expressions, no neutral frames
        var frames: [UIImage] = []
        var frameDurations: [TimeInterval] = []

        // Add each expression frame
        for (index, expression) in expressions.enumerated() {
            guard let expressionSprite = sprites[expression] else {
                print("⚠️ Missing sprite for expression: \(expression.rawValue)")
                throw GIFError.invalidSprite
            }

            // Add overlays: expression name, frame number, and ID (first frame only)
            let frameNumber = index + 1
            var frameWithOverlays = addExpressionName(to: expressionSprite, expression: expression)
            frameWithOverlays = addFrameNumber(to: frameWithOverlays, frameNumber: frameNumber)
            
            // Add ID overlay to first expression frame
            if index == 0 {
                frameWithOverlays = addIDOverlay(to: frameWithOverlays, messageID: messageID)
            }

            // Expression frame
            frames.append(frameWithOverlays)
            
            // Frame 1 holds for 1.5s, other frames for 0.7s
            if index == 0 {
                frameDurations.append(1.5)
            } else {
                frameDurations.append(0.7)
            }
        }

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

    /// Add expression name to bottom left (bottom 10%) of image
    private static func addExpressionName(to image: UIImage, expression: FaceExpression) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: image.size)

        return renderer.image { context in
            // Draw original image
            image.draw(in: CGRect(origin: .zero, size: image.size))

            // Configure text - larger, bold font with strong outline
            let fontSize: CGFloat = 20
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: fontSize),
                .foregroundColor: UIColor.white,
                .strokeColor: UIColor.black,
                .strokeWidth: -5.0  // Negative for fill + stroke
            ]

            let text = expression.displayName
            let attributedText = NSAttributedString(string: text, attributes: attributes)

            // Calculate text position (bottom left, in bottom 10% area)
            let textSize = attributedText.size()
            let padding: CGFloat = 12
            let textRect = CGRect(
                x: padding,
                y: image.size.height - textSize.height - padding,
                width: textSize.width,
                height: textSize.height
            )

            // Draw text
            attributedText.draw(in: textRect)
        }
    }
    
    /// Add frame number to bottom right corner of image
    private static func addFrameNumber(to image: UIImage, frameNumber: Int) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: image.size)

        return renderer.image { context in
            // Draw original image
            image.draw(in: CGRect(origin: .zero, size: image.size))

            // Configure text - small font with black outline
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 18),
                .foregroundColor: UIColor.white,
                .strokeColor: UIColor.black,
                .strokeWidth: -4.0  // Negative for fill + stroke
            ]

            let text = "\(frameNumber)"
            let attributedText = NSAttributedString(string: text, attributes: attributes)

            // Calculate text position (bottom-right corner)
            let textSize = attributedText.size()
            let padding: CGFloat = 12
            let textRect = CGRect(
                x: image.size.width - textSize.width - padding,
                y: image.size.height - textSize.height - padding,
                width: textSize.width,
                height: textSize.height
            )

            // Draw text
            attributedText.draw(in: textRect)
        }
    }

    /// Add subtle ID overlay to image (top-left corner)
    private static func addIDOverlay(to image: UIImage, messageID: String) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: image.size)

        return renderer.image { context in
            // Draw original image
            image.draw(in: CGRect(origin: .zero, size: image.size))

            // Configure text - smaller, more subtle
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 10),  // Smaller font
                .foregroundColor: UIColor.white.withAlphaComponent(0.7),  // Semi-transparent white
                .strokeColor: UIColor.black.withAlphaComponent(0.5),  // Semi-transparent black
                .strokeWidth: -2.0  // Thinner stroke
            ]

            let text = "ID:\(messageID)"
            let attributedText = NSAttributedString(string: text, attributes: attributes)

            // Calculate text position (top-left corner with small padding)
            let textSize = attributedText.size()
            let textRect = CGRect(
                x: 6,
                y: 6,
                width: textSize.width,
                height: textSize.height
            )

            // Draw text without background for more subtlety
            attributedText.draw(in: textRect)
        }
    }
}
