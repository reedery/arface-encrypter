//
//  AnimatedGIFView.swift
//  arface-encrypter
//
//  Created by Claude Code
//

import SwiftUI
import UIKit
import ImageIO

/// SwiftUI view for displaying animated GIFs
struct AnimatedGIFView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> UIImageView {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true

        // Load and animate GIF
        loadAnimatedGIF(into: imageView, from: url)

        return imageView
    }

    func updateUIView(_ uiView: UIImageView, context: Context) {
        // Reload GIF if URL changes
        loadAnimatedGIF(into: uiView, from: url)
    }

    private func loadAnimatedGIF(into imageView: UIImageView, from url: URL) {
        guard let imageData = try? Data(contentsOf: url),
              let source = CGImageSourceCreateWithData(imageData as CFData, nil) else {
            print("⚠️ Failed to load GIF from \(url)")
            return
        }

        let frameCount = CGImageSourceGetCount(source)
        var images: [UIImage] = []
        var totalDuration: TimeInterval = 0

        // Extract all frames
        for i in 0..<frameCount {
            guard let cgImage = CGImageSourceCreateImageAtIndex(source, i, nil) else { continue }

            // Get frame duration
            let frameDuration = getFrameDuration(from: source, at: i)
            totalDuration += frameDuration

            images.append(UIImage(cgImage: cgImage))
        }

        guard !images.isEmpty else {
            print("⚠️ No frames found in GIF")
            return
        }

        // Set up animation
        imageView.animationImages = images
        imageView.animationDuration = totalDuration
        imageView.animationRepeatCount = 0  // 0 = loop forever
        imageView.startAnimating()

        print("✅ GIF loaded: \(frameCount) frames, \(String(format: "%.1f", totalDuration))s duration")
    }

    private func getFrameDuration(from source: CGImageSource, at index: Int) -> TimeInterval {
        // Default duration
        var duration: TimeInterval = 0.1

        // Get frame properties
        guard let properties = CGImageSourceCopyPropertiesAtIndex(source, index, nil) as? [String: Any],
              let gifProperties = properties[kCGImagePropertyGIFDictionary as String] as? [String: Any] else {
            return duration
        }

        // Try to get delay time
        if let delayTime = gifProperties[kCGImagePropertyGIFDelayTime as String] as? TimeInterval, delayTime > 0 {
            duration = delayTime
        } else if let unclampedDelayTime = gifProperties[kCGImagePropertyGIFUnclampedDelayTime as String] as? TimeInterval, unclampedDelayTime > 0 {
            duration = unclampedDelayTime
        }

        return duration
    }
}

#Preview {
    // Preview with a sample GIF (will fail if no GIF exists, but shows the structure)
    if let url = Bundle.main.url(forResource: "sample", withExtension: "gif") {
        AnimatedGIFView(url: url)
            .frame(width: 300, height: 300)
    } else {
        Text("No sample GIF available for preview")
            .foregroundStyle(.secondary)
    }
}
