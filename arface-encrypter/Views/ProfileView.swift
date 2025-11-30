//
//  ProfileView.swift
//  arface-encrypter
//
//  Created by ryan reede on 11/30/25.
//

import SwiftUI

struct ProfileView: View {
    @State private var userSettings = UserSettings()
    @State private var sprites: [FaceExpression: UIImage] = [:]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 30) {
                    // Avatar Selection Section
                    VStack(spacing: 16) {
                        Text("Choose Your Avatar")
                            .font(.headline)

                        // Avatar Picker
                        Picker("Avatar", selection: $userSettings.selectedAvatar) {
                            ForEach(AvatarType.allCases, id: \.self) { avatar in
                                Text("\(avatar.displayName) \(avatar == .bear ? "🐻" : "🦊")")
                                    .tag(avatar)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)
                    }
                    .padding(.top)

                    Divider()

                    // Sprite Preview Grid
                    VStack(spacing: 16) {
                        Text("Expression Preview")
                            .font(.headline)

                        if sprites.isEmpty {
                            ProgressView("Loading sprites...")
                                .padding()
                        } else {
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 16) {
                                ForEach(FaceExpression.allCases, id: \.self) { expression in
                                    VStack(spacing: 8) {
                                        if let sprite = sprites[expression] {
                                            Image(uiImage: sprite)
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .frame(width: 100, height: 100)
                                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                                )
                                        } else {
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color.gray.opacity(0.2))
                                                .frame(width: 100, height: 100)
                                        }

                                        Text(expression.emoji)
                                            .font(.title3)

                                        Text(expression.displayName)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }

                    Divider()

                    // User Stats Section (Placeholder for now)
                    VStack(spacing: 12) {
                        Text("Stats")
                            .font(.headline)

                        HStack(spacing: 40) {
                            VStack {
                                Text("0")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                Text("Encoded")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            VStack {
                                Text("0")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                Text("Decoded")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal)

                    Spacer()
                }
            }
            .navigationTitle("Profile")
            .task {
                // Load sprites when view appears
                loadSprites()
            }
            .onChange(of: userSettings.selectedAvatar) { _, _ in
                // Reload sprites when avatar changes
                loadSprites()
            }
        }
    }

    private func loadSprites() {
        Task {
            let extractedSprites = SpriteSheetExtractor.extractAllSprites(from: userSettings.selectedAvatar)
            await MainActor.run {
                withAnimation {
                    sprites = extractedSprites
                }
            }
        }
    }
}

#Preview {
    ProfileView()
}
