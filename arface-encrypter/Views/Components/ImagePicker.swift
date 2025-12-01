//
//  ImagePicker.swift
//  arface-encrypter
//
//  Created by Claude Code
//

import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

/// SwiftUI wrapper for PHPickerViewController to select GIF images
/// Copies the selected GIF to a temporary location and returns its URL
struct ImagePicker: UIViewControllerRepresentable {
    let onSelect: (URL) -> Void
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.filter = .images
        config.selectionLimit = 1
        config.preferredAssetRepresentationMode = .current
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onSelect: onSelect)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let onSelect: (URL) -> Void
        
        init(onSelect: @escaping (URL) -> Void) {
            self.onSelect = onSelect
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            
            guard let provider = results.first?.itemProvider else {
                print("⚠️ No item provider found")
                return
            }
            
            print("🖼️ Image picker: Loading selected item")
            
            // Try to load as GIF first
            if provider.hasItemConformingToTypeIdentifier(UTType.gif.identifier) {
                loadGIF(from: provider)
            } else if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                // Fallback: try loading as generic image (might still be a GIF)
                loadImage(from: provider)
            } else {
                print("⚠️ Selected item is not a supported image type")
            }
        }
        
        private func loadGIF(from provider: NSItemProvider) {
            provider.loadFileRepresentation(forTypeIdentifier: UTType.gif.identifier) { url, error in
                if let error = error {
                    print("❌ Error loading GIF: \(error.localizedDescription)")
                    return
                }
                
                guard let url = url else {
                    print("⚠️ No URL provided for GIF")
                    return
                }
                
                self.copyToTempLocation(url: url)
            }
        }
        
        private func loadImage(from provider: NSItemProvider) {
            provider.loadFileRepresentation(forTypeIdentifier: UTType.image.identifier) { url, error in
                if let error = error {
                    print("❌ Error loading image: \(error.localizedDescription)")
                    return
                }
                
                guard let url = url else {
                    print("⚠️ No URL provided for image")
                    return
                }
                
                self.copyToTempLocation(url: url)
            }
        }
        
        private func copyToTempLocation(url: URL) {
            // Copy to temp directory since the provided URL might be temporary
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension(url.pathExtension)
            
            do {
                // Remove existing file if present
                if FileManager.default.fileExists(atPath: tempURL.path) {
                    try FileManager.default.removeItem(at: tempURL)
                }
                
                try FileManager.default.copyItem(at: url, to: tempURL)
                print("✅ GIF copied to temp location: \(tempURL.lastPathComponent)")
                
                DispatchQueue.main.async {
                    self.onSelect(tempURL)
                }
            } catch {
                print("❌ Error copying GIF to temp location: \(error.localizedDescription)")
            }
        }
    }
}

