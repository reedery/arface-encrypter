//
//  ImagePlaygroundService.swift
//  arface-encrypter
//
//  Created by Claude Code
//

import Foundation
import UIKit
import ImagePlayground

/// Service for generating AI-enhanced images using Apple's Image Playground API
@MainActor
class ImagePlaygroundService {
    
    enum ImagePlaygroundError: LocalizedError {
        case generationFailed
        case cancelled
        
        var errorDescription: String? {
            switch self {
            case .generationFailed:
                return "Failed to generate image - Image Playground may not be available on this device"
            case .cancelled:
                return "Image generation was cancelled"
            }
        }
    }
    
    /// Generate an AI-enhanced image using a sprite frame as concept
    /// - Parameters:
    ///   - spriteImage: The original sprite frame to use as concept
    ///   - avatar: The avatar type (bear or fox)
    ///   - expression: The facial expression
    /// - Returns: AI-generated UIImage at 256x256 resolution
    static func generateEnhancedFrame(
        spriteImage: UIImage,
        avatar: AvatarType,
        expression: FaceExpression
    ) async throws -> UIImage {
        
        print("🎨 Generating AI-enhanced frame for \(avatar.displayName) - \(expression.displayName)")
        
        // Build the prompt based on avatar and expression
        let prompt = buildPrompt(for: avatar, expression: expression)
        print("   Prompt: \(prompt)")
        
        // Generate the image with Image Playground
        do {
            // Initialize ImageCreator
            let creator = try await ImageCreator()
            
            // Create concepts: text prompt + image reference for style matching
            guard let spriteCGImage = spriteImage.cgImage else {
                throw ImagePlaygroundError.generationFailed
            }
            
            let concepts: [ImagePlaygroundConcept] = [
                .text(prompt),
                .image(spriteCGImage)
            ]
            
            // Generate image with cartoon style for emoji-like cute aesthetic
            let results = creator.images(
                for: concepts,
                style: .animation,
                limit: 1
            )
            
            // Get the first generated image
            if let first = try await results.first(where: { _ in true }) {
                let generatedImage = UIImage(cgImage: first.cgImage)
                
                // Resize to 256x256 for consistency with sprite dimensions
                let resizedImage = resizeToSpriteSize(generatedImage)
                
                print("✅ Successfully generated AI-enhanced frame (resized to 256x256)")
                return resizedImage
            }
            
            throw ImagePlaygroundError.generationFailed
            
        } catch ImageCreator.Error.notSupported {
            print("❌ Image Playground not supported on this device")
            throw ImagePlaygroundError.generationFailed
        } catch let error as ImagePlaygroundError {
            print("❌ Image generation failed: \(error.localizedDescription)")
            throw error
        } catch {
            print("❌ Image generation failed: \(error.localizedDescription)")
            throw ImagePlaygroundError.generationFailed
        }
    }
    
    /// Build a descriptive prompt for image generation
    /// - Parameters:
    ///   - avatar: The avatar type
    ///   - expression: The facial expression
    /// - Returns: Simple, clear prompt string
    private static func buildPrompt(for avatar: AvatarType, expression: FaceExpression) -> String {
        // Simple character description
        let character: String
        switch avatar {
        case .bear:
            character = "cute brown bear"
        case .fox:
            character = "cute orange fox"
        }
        
        // Simple expression description
        let expressionDesc: String
        switch expression {
        case .winkLeft, .winkRight:
            expressionDesc = "winking"
        case .tongueOut:
            expressionDesc = "with tongue out"
        case .surprise:
            expressionDesc = "surprised with mouth open"
        case .smile:
            expressionDesc = "smiling happily"
        case .smooch:
            expressionDesc = "blowing a kiss"
        }
        
        // Simple, short prompt
        return "A \(character) emoji \(expressionDesc) on white background"
    }
    
    /// Batch generate multiple frames (used for GIF generation)
    /// - Parameters:
    ///   - frames: Array of tuples containing sprite image, avatar, and expression
    ///   - onFrameGenerated: Optional callback called when each frame is generated
    /// - Returns: Array of AI-generated images
    static func generateEnhancedFrames(
        frames: [(spriteImage: UIImage, avatar: AvatarType, expression: FaceExpression)],
        onFrameGenerated: (@MainActor (UIImage, Int) -> Void)? = nil
    ) async throws -> [UIImage] {
        
        var enhancedFrames: [UIImage] = []
        
        for (index, frame) in frames.enumerated() {
            print("🎨 Generating frame \(index + 1)/\(frames.count)")
            
            let enhancedImage = try await generateEnhancedFrame(
                spriteImage: frame.spriteImage,
                avatar: frame.avatar,
                expression: frame.expression
            )
            
            enhancedFrames.append(enhancedImage)
            
            // Notify callback that frame is ready
            await onFrameGenerated?(enhancedImage, index)
        }
        
        return enhancedFrames
    }
    
    /// Resize generated image to 256x256 to match sprite dimensions
    /// - Parameter image: The generated image to resize
    /// - Returns: Resized UIImage at 256x256
    private static func resizeToSpriteSize(_ image: UIImage) -> UIImage {
        let targetSize = AvatarType.spriteSize // 256x256
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { context in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
}

