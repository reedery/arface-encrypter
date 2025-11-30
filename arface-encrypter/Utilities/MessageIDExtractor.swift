//
//  MessageIDExtractor.swift
//  arface-encrypter
//
//  Created by Claude Code
//

import UIKit
import Vision
import ImageIO

/// Extracts message ID from GIF images using OCR
class MessageIDExtractor {

    /// Extract message ID from a GIF file
    /// Reads the last frame and uses Vision OCR to find "ID:12345" text
    /// - Parameter gifURL: URL to the GIF file
    /// - Returns: The extracted message ID (number only), or nil if not found
    static func extractMessageID(from gifURL: URL) async -> String? {
        print("🔍 Extracting message ID from GIF: \(gifURL.lastPathComponent)")

        // Load GIF and get last frame
        guard let lastFrame = await getLastFrame(from: gifURL) else {
            print("⚠️ Failed to get last frame from GIF")
            return nil
        }

        // Extract text from image using Vision OCR
        guard let text = await extractTextFromImage(lastFrame) else {
            print("⚠️ No text found in image")
            return nil
        }

        print("   Extracted text: '\(text)'")

        // Parse message ID from text (format: "ID:12345")
        let messageID = parseMessageID(from: text)

        if let messageID = messageID {
            print("✅ Message ID extracted: \(messageID)")
        } else {
            print("⚠️ Could not parse message ID from text")
        }

        return messageID
    }

    /// Get the last frame from a GIF
    private static func getLastFrame(from gifURL: URL) async -> UIImage? {
        guard let imageSource = CGImageSourceCreateWithURL(gifURL as CFURL, nil) else {
            return nil
        }

        let frameCount = CGImageSourceGetCount(imageSource)
        guard frameCount > 0 else { return nil }

        // Get last frame (index = frameCount - 1)
        let lastFrameIndex = frameCount - 1

        guard let cgImage = CGImageSourceCreateImageAtIndex(imageSource, lastFrameIndex, nil) else {
            return nil
        }

        return UIImage(cgImage: cgImage)
    }

    /// Extract text from an image using Vision OCR
    private static func extractTextFromImage(_ image: UIImage) async -> String? {
        guard let cgImage = image.cgImage else { return nil }

        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = false

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

        do {
            try handler.perform([request])

            guard let observations = request.results, !observations.isEmpty else {
                return nil
            }

            // Combine all recognized text
            let recognizedStrings = observations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }

            return recognizedStrings.joined(separator: " ")

        } catch {
            print("⚠️ Vision OCR error: \(error.localizedDescription)")
            return nil
        }
    }

    /// Parse message ID from extracted text
    /// Looks for patterns like "ID:123", "ID: 123", or just the number
    private static func parseMessageID(from text: String) -> String? {
        // Remove whitespace
        let cleanText = text.replacingOccurrences(of: " ", with: "")

        // Pattern 1: "ID:123" or "ID:12345"
        if let range = cleanText.range(of: "ID:", options: .caseInsensitive) {
            let afterID = cleanText[range.upperBound...]
            let digits = afterID.prefix(while: { $0.isNumber })
            if !digits.isEmpty {
                return String(digits)
            }
        }

        // Pattern 2: Look for any sequence of digits
        let digitPattern = try? NSRegularExpression(pattern: "\\d+", options: [])
        if let match = digitPattern?.firstMatch(in: cleanText, options: [], range: NSRange(cleanText.startIndex..., in: cleanText)) {
            if let range = Range(match.range, in: cleanText) {
                return String(cleanText[range])
            }
        }

        return nil
    }
}
