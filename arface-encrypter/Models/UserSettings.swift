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

    var selectedAvatar: AvatarType {
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
    }

    private func saveToUserDefaults() {
        UserDefaults.standard.set(selectedAvatar.rawValue, forKey: Self.selectedAvatarKey)
    }
}
