//
//  DecodeViewModel.swift
//  arface-encrypter
//
//  Created by ryan reede on 11/30/25.
//

import Foundation
import Observation

/// View model for the decode flow
/// Manages message fetching and display from the database
@MainActor
@Observable
final class DecodeViewModel {
    
    // MARK: - State Properties
    
    var messages: [Message] = []
    var isLoading = false
    var errorMessage: String?
    
    // MARK: - Public Methods
    
    /// Fetch all messages from the database
    func fetchMessages() async {
        isLoading = true
        errorMessage = nil
        
        do {
            messages = try await MessageService.shared.fetchAllMessages()
            print("📋 Fetched \(messages.count) messages")
        } catch {
            print("❌ Error fetching messages: \(error.localizedDescription)")
            handleError(error)
        }
        
        isLoading = false
    }
    
    // MARK: - Private Methods
    
    private func handleError(_ error: Error) {
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet:
                errorMessage = "No internet connection. Please check your network."
            case .timedOut:
                errorMessage = "Request timed out. Please try again."
            default:
                errorMessage = "Network error: \(urlError.localizedDescription)"
            }
        } else {
            errorMessage = error.localizedDescription
        }
    }
}
