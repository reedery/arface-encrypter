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
            
            // Generate image with illustration style for Genmoji-like 3D rendered appearance
            // The prompt specifies Genmoji style for emoji-like cute aesthetic
            let results = creator.images(
                for: concepts,
                style: .illustration,
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
    /// - Returns: Detailed prompt string with clear instructions for consistency
    private static func buildPrompt(for avatar: AvatarType, expression: FaceExpression) -> String {
        // Character-specific descriptions for consistency with EXTRA CUTE emphasis
        let characterDescription: String
        switch avatar {
        case .bear:
            characterDescription = "adorable kawaii brown teddy bear with big round ears, large expressive eyes, a small button nose, chubby round cheeks, and soft warm brown fur. Ultra-cute and endearing with a baby-like innocent appearance"
        case .fox:
            characterDescription = "adorable kawaii orange fox with big triangular ears, huge expressive eyes, fluffy white cheeks, a tiny delicate snout, and bright vibrant orange fur with white fluffy accents. Ultra-cute and charming with a sweet innocent appearance"
        }
        
        // Expression-specific descriptions with FORCEFUL, EXAGGERATED features
        let expressionDescription: String
        switch expression {
        case .winkLeft:
            expressionDescription = "CRITICAL: ONE EYE WINKING. The character's LEFT eye (viewer's left when looking at the face) is COMPLETELY SHUT CLOSED in a clear obvious wink. The RIGHT eye (viewer's right) is FULLY WIDE OPEN, big and bright. This is a VERY CLEAR LEFT EYE WINK - left eye closed, right eye open. NOT both eyes closed. NOT both eyes open. Asymmetric expression with one eye shut."
        case .winkRight:
            expressionDescription = "CRITICAL: ONE EYE WINKING. The character's RIGHT eye (viewer's right when looking at the face) is COMPLETELY SHUT CLOSED in a clear obvious wink. The LEFT eye (viewer's left) is FULLY WIDE OPEN, big and bright. This is a VERY CLEAR RIGHT EYE WINK - right eye closed, left eye open. NOT both eyes closed. NOT both eyes open. Asymmetric expression with one eye shut."
        case .tongueOut:
            expressionDescription = "Pink tongue sticking FAR OUT of the mouth, very long and extended. Tongue is the main focus, extremely visible and prominent. Playful silly expression with tongue hanging out."
        case .surprise:
            expressionDescription = "Eyes are EXTREMELY wide open and huge, eyebrows raised HIGH above the eyes, mouth open in a big round O shape. Maximum shocked and surprised expression with exaggerated features."
        case .smile:
            expressionDescription = "HUGE wide happy smile with a big grin, sparkling cheerful eyes. Extremely joyful and delighted expression radiating happiness."
        case .smooch:
            expressionDescription = "Lips puckered forward into an exaggerated kissing pose, making a clear kiss face. Very obvious smooch expression."
        }
        
        // Build comprehensive prompt with STRICT instructions - Genmoji style
        return """
        Genmoji style emoji character. An ultra-cute super adorable \(characterDescription) character. \
        \(expressionDescription) \
        MANDATORY: Perfectly centered on a SOLID PURE WHITE background (#FFFFFF). NO blue, NO colors in background - ONLY WHITE. \
        The character face is large and fills most of the frame, facing directly forward toward viewer. \
        Clean bright studio lighting with no shadows. Perfect even illumination across the face. \
        Art style: Genmoji emoji style - extremely cute kawaii aesthetic, round soft shapes, glossy finish, gentle gradients, oversized expressive features, innocent childlike charm. \
        3D rendered look with smooth surfaces and vibrant saturated colors. Maximum adorable cuteness factor. \
        Background: SOLID WHITE ONLY. No gradients, no blue, no other colors.
        """
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

