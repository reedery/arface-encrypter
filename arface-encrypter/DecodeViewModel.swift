//
//  DecodeViewModel.swift
//  arface-encrypter
//
//  Created by ryan reede on 11/30/25.
//

import Foundation
import Supabase
import Observation

@MainActor
@Observable
final class DecodeViewModel {
    var messages: [Message] = []
    var isLoading = false
    var errorMessage: String?
    
    func fetchMessages() async {
        isLoading = true
        errorMessage = nil
        
        do {
            messages = try await SupabaseConfig.shared.client
                .from("messages")
                .select()
                .order("created_at", ascending: false)
                .execute()
                .value
            
            debugPrint("Fetched \(messages.count) messages")
            
        } catch {
            debugPrint(error)
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}
