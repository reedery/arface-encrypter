//
//  UserSettings.swift
//  arface-encrypter
//
//  Created by Claude Code
//

import Foundation
import SwiftUI

@Observable
class UserSettings {
    // Shared singleton instance
    static let shared = UserSettings()
    
    private static let selectedAvatarKey = "selectedAvatar"
    private static let encodedCountKey = "encodedCount"
    private static let decodedCountKey = "decodedCount"
    private static let aiImageGenerationKey = "aiImageGeneration"
    private static let offlineModeKey = "offlineMode"

    var selectedAvatar: AvatarType {
        didSet {
            saveToUserDefaults()
            print("📝 Avatar changed to: \(selectedAvatar.displayName)")
        }
    }
    
    var encodedCount: Int {
        didSet {
            saveToUserDefaults()
        }
    }
    
    var decodedCount: Int {
        didSet {
            saveToUserDefaults()
        }
    }
    
    var useAIImageGeneration: Bool {
        didSet {
            saveToUserDefaults()
            print("📝 AI Image Generation changed to: \(useAIImageGeneration)")
        }
    }
    
    var offlineMode: Bool {
        didSet {
            saveToUserDefaults()
            print("📝 Offline Mode changed to: \(offlineMode)")
        }
    }

    private init() {
        // Load from UserDefaults or default to bear
        if let savedValue = UserDefaults.standard.string(forKey: Self.selectedAvatarKey),
           let avatar = AvatarType(rawValue: savedValue) {
            self.selectedAvatar = avatar
        } else {
            self.selectedAvatar = .bear
        }
        
        // Load stats from UserDefaults
        self.encodedCount = UserDefaults.standard.integer(forKey: Self.encodedCountKey)
        self.decodedCount = UserDefaults.standard.integer(forKey: Self.decodedCountKey)
        
        // Load AI image generation setting (default to true if not set)
        if UserDefaults.standard.object(forKey: Self.aiImageGenerationKey) != nil {
            self.useAIImageGeneration = UserDefaults.standard.bool(forKey: Self.aiImageGenerationKey)
        } else {
            self.useAIImageGeneration = true
        }
        
        // Load offline mode setting (default to true/ON if not set)
        if UserDefaults.standard.object(forKey: Self.offlineModeKey) != nil {
            self.offlineMode = UserDefaults.standard.bool(forKey: Self.offlineModeKey)
        } else {
            self.offlineMode = true
        }
        
        print("⚙️ UserSettings initialized - AI Generation: \(useAIImageGeneration), Offline: \(offlineMode), Avatar: \(selectedAvatar.displayName)")
    }

    private func saveToUserDefaults() {
        UserDefaults.standard.set(selectedAvatar.rawValue, forKey: Self.selectedAvatarKey)
        UserDefaults.standard.set(encodedCount, forKey: Self.encodedCountKey)
        UserDefaults.standard.set(decodedCount, forKey: Self.decodedCountKey)
        UserDefaults.standard.set(useAIImageGeneration, forKey: Self.aiImageGenerationKey)
        UserDefaults.standard.set(offlineMode, forKey: Self.offlineModeKey)
        UserDefaults.standard.synchronize()  // Force sync to disk
    }
    
    /// Increment the encoded messages count
    func incrementEncodedCount() {
        encodedCount += 1
    }
    
    /// Increment the decoded messages count
    func incrementDecodedCount() {
        decodedCount += 1
    }
}
