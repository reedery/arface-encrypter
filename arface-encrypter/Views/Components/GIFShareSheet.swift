//
//  GIFShareSheet.swift
//  arface-encrypter
//
//  Created by Claude Code
//

import SwiftUI
import UIKit
import UniformTypeIdentifiers

/// Wrapper view for UIActivityViewController
struct GIFShareSheet: View {
    let gifURL: URL
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ActivityViewController(gifURL: gifURL)
            .ignoresSafeArea()
    }
}

/// Item provider that properly identifies the GIF file type
private class GIFItemProvider: NSObject, UIActivityItemSource {
    let gifURL: URL
    let gifData: Data?
    
    init(gifURL: URL) {
        self.gifURL = gifURL
        self.gifData = try? Data(contentsOf: gifURL)
        super.init()
    }
    
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        // Return the URL as placeholder
        return gifURL
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        // Return the actual URL
        return gifURL
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, dataTypeIdentifierForActivityType activityType: UIActivity.ActivityType?) -> String {
        // Explicitly identify as GIF
        return UTType.gif.identifier
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivity.ActivityType?) -> String {
        return "Secret Message"
    }
}

/// UIViewControllerRepresentable wrapper for UIActivityViewController
private struct ActivityViewController: UIViewControllerRepresentable {
    let gifURL: URL
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        print("📤 Preparing to share GIF: \(gifURL.path)")
        print("   File exists: \(FileManager.default.fileExists(atPath: gifURL.path))")
        
        if let fileSize = try? FileManager.default.attributesOfItem(atPath: gifURL.path)[.size] as? Int {
            print("   File size: \(fileSize) bytes")
        }
        
        // Create item provider with proper GIF type
        let itemProvider = GIFItemProvider(gifURL: gifURL)
        
        // Create activity view controller
        let controller = UIActivityViewController(
            activityItems: [itemProvider],
            applicationActivities: nil
        )
        
        // Exclude activities that don't make sense for GIFs
        controller.excludedActivityTypes = [
            .assignToContact,
            .addToReadingList,
            .openInIBooks
        ]
        
        // Set completion handler
        controller.completionWithItemsHandler = { activityType, completed, _, error in
            if let error = error {
                print("❌ Share error: \(error.localizedDescription)")
            } else if completed {
                print("✅ Share completed: \(activityType?.rawValue ?? "unknown")")
            } else {
                print("⚠️ Share cancelled")
            }
        }
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No updates needed
    }
}

/// View modifier to present the GIF share sheet
struct GIFShareSheetModifier: ViewModifier {
    @Binding var isPresented: Bool
    let gifURL: URL?
    
    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $isPresented) {
                if let gifURL = gifURL {
                    GIFShareSheet(gifURL: gifURL)
                }
            }
    }
}

extension View {
    /// Present a share sheet for a GIF file
    func gifShareSheet(isPresented: Binding<Bool>, gifURL: URL?) -> some View {
        modifier(GIFShareSheetModifier(isPresented: isPresented, gifURL: gifURL))
    }
}

