//
//  DecodeView.swift
//  arface-encrypter
//
//  Created by ryan reede on 11/30/25.
//

import SwiftUI

struct DecodeView: View {
    @State private var viewModel = DecodeViewModel()
    
    var body: some View {
        NavigationStack {
            contentView
                .navigationTitle("Decode")
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            Task {
                                await viewModel.fetchMessages()
                            }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                }
                .task {
                    await viewModel.fetchMessages()
                }
        }
    }
    
    // MARK: - Subviews
    
    @ViewBuilder
    private var contentView: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Loading messages...")
            } else if let error = viewModel.errorMessage {
                errorView(error)
            } else if viewModel.messages.isEmpty {
                emptyStateView
            } else {
                messageListView
            }
        }
    }
    
    private func errorView(_ error: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundStyle(.orange)
            Text("Error")
                .font(.headline)
            Text(error)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Button("Retry") {
                Task {
                    await viewModel.fetchMessages()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
    
    private var emptyStateView: some View {
        ContentUnavailableView(
            "No Messages",
            systemImage: "tray.fill",
            description: Text("No messages found in your database.")
        )
    }
    
    private var messageListView: some View {
        List(viewModel.messages) { message in
            MessageRowView(message: message)
        }
        .refreshable {
            await viewModel.fetchMessages()
        }
    }
}

// MARK: - Message Row View

struct MessageRowView: View {
    let message: Message
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("ID: \(message.id)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(message.createdAt, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            if let expressionHash = message.expressionHash {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Expression Hash:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(expressionHash)
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(.blue)
                }
            }
            
            if let messageText = message.message {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Message:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(messageText)
                        .font(.body)
                }
            }
            
            if let expressionList = message.expressionList {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Expression List:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(expressionList)
                        .font(.system(.body, design: .monospaced))
                        .lineLimit(3)
                        .foregroundStyle(.green)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    DecodeView()
}
