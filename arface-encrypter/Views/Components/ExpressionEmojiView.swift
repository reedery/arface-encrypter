//
//  ExpressionEmojiView.swift
//  arface-encrypter
//
//  Created by Claude Code
//

import SwiftUI

/// Displays an emoji with optional horizontal flip for right wink
/// Used across the app to show facial expression emojis consistently
struct ExpressionEmojiView: View {
    let expression: FaceExpression

    var body: some View {
        Text(expression.emoji)
            .scaleEffect(x: expression.shouldFlipEmoji ? -1 : 1, y: 1)
    }
}

#Preview {
    HStack(spacing: 20) {
        ForEach(FaceExpression.allCases, id: \.self) { expression in
            VStack {
                ExpressionEmojiView(expression: expression)
                    .font(.system(size: 60))
                Text(expression.displayName)
                    .font(.caption)
            }
        }
    }
    .padding()
}

