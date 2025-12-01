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
    private static let selectedAvatarKey = "selectedAvatar"
    private static let encodedCountKey = "encodedCount"
    private static let decodedCountKey = "decodedCount"
    private static let aiImageGenerationKey = "aiImageGeneration"

    var selectedAvatar: AvatarType {
        didSet {
            saveToUserDefaults()
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
        }
    }

    init() {
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
    }

    private func saveToUserDefaults() {
        UserDefaults.standard.set(selectedAvatar.rawValue, forKey: Self.selectedAvatarKey)
        UserDefaults.standard.set(encodedCount, forKey: Self.encodedCountKey)
        UserDefaults.standard.set(decodedCount, forKey: Self.decodedCountKey)
        UserDefaults.standard.set(useAIImageGeneration, forKey: Self.aiImageGenerationKey)
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
