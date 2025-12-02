//
//  MessageService.swift
//  arface-encrypter
//
//  Created by Claude Code
//

import Foundation
import Supabase

/// Service for managing messages in Supabase or locally (offline mode)
class MessageService {
    static let shared = MessageService()
    
    private var client: SupabaseClient? { SupabaseConfig.shared.client }
    private let offlineStore = OfflineMessageStore.shared
    
    private init() {}
    
    // MARK: - Helper Types
    
    /// Data structure for inserting a new message
    private struct MessageInsert: Encodable {
        let expressionHash: String
        let message: String
        let expressionList: String
        
        enum CodingKeys: String, CodingKey {
            case expressionHash = "expression_hash"
            case message
            case expressionList = "expression_list"
        }
    }
    
    // MARK: - Mode Helpers
    
    /// Whether we should use offline storage
    private var shouldUseOfflineMode: Bool {
        UserSettings.shared.offlineMode || !SupabaseConfig.shared.isConfigured
    }
    
    // MARK: - Public Methods
    
    /// Create a new message in the database or locally
    /// - Parameters:
    ///   - expressionHash: Comma-separated expression IDs (e.g. "wink_l,tongue_out,surprise,smile,smooch")
    ///   - message: The secret message text
    ///   - expressionList: Same as expressionHash (redundant for now, kept for schema compatibility)
    /// - Returns: The created Message with auto-generated ID
    func createMessage(
        expressionHash: String,
        message: String,
        expressionList: String
    ) async throws -> Message {
        print("📝 Creating message with hash: \(expressionHash)")
        
        // Use offline storage if offline mode is on or Supabase isn't configured
        if shouldUseOfflineMode {
            print("📴 Using offline storage")
            let offlineMessage = offlineStore.saveMessage(
                expressionHash: expressionHash,
                message: message,
                expressionList: expressionList
            )
            return offlineMessage
        }
        
        // Try Supabase, fallback to offline on failure
        guard let client = client else {
            print("⚠️ Supabase not configured, falling back to offline storage")
            return offlineStore.saveMessage(
                expressionHash: expressionHash,
                message: message,
                expressionList: expressionList
            )
        }
        
        do {
            // Create the insert payload
            let insertData = MessageInsert(
                expressionHash: expressionHash,
                message: message,
                expressionList: expressionList
            )
            
            let response: Message = try await client
                .from("messages")
                .insert(insertData)
                .select()
                .single()
                .execute()
                .value
            
            print("✅ Message created with ID: \(response.id)")
            return response
        } catch {
            // Graceful fallback to offline mode on any Supabase error
            print("⚠️ Supabase error: \(error.localizedDescription)")
            print("📴 Falling back to offline storage")
            let offlineMessage = offlineStore.saveMessage(
                expressionHash: expressionHash,
                message: message,
                expressionList: expressionList
            )
            return offlineMessage
        }
    }
    
    /// Fetch a message by its expression hash
    /// - Parameter hash: The expression hash to search for
    /// - Returns: The matching message or nil if not found
    func fetchMessage(byHash hash: String) async throws -> Message? {
        print("🔍 Fetching message with hash: \(hash)")
        
        // Always check offline storage first (messages might be stored there)
        if let offlineMessage = offlineStore.fetchMessage(byHash: hash) {
            return offlineMessage
        }
        
        // If offline mode or no client, we're done
        if shouldUseOfflineMode {
            print("📴 Offline mode - no message found locally")
            return nil
        }
        
        guard let client = client else {
            return nil
        }
        
        do {
            let response: Message = try await client
                .from("messages")
                .select()
                .eq("expression_hash", value: hash)
                .limit(1)
                .single()
                .execute()
                .value
            
            print("✅ Found message ID: \(response.id)")
            return response
        } catch {
            // If no message found, return nil instead of throwing
            print("❌ No message found with hash: \(hash)")
            return nil
        }
    }
    
    /// Fetch all messages ordered by creation date (newest first)
    /// - Returns: Array of all messages
    func fetchAllMessages() async throws -> [Message] {
        print("📋 Fetching all messages")
        
        // In offline mode, return only local messages
        if shouldUseOfflineMode {
            let offlineMessages = offlineStore.fetchAllMessages()
            print("📴 Fetched \(offlineMessages.count) offline messages")
            return offlineMessages
        }
        
        guard let client = client else {
            return offlineStore.fetchAllMessages()
        }
        
        do {
            let response: [Message] = try await client
                .from("messages")
                .select()
                .order("created_at", ascending: false)
                .execute()
                .value
            
            // Combine with offline messages
            let offlineMessages = offlineStore.fetchAllMessages()
            let combined = offlineMessages + response
            
            print("✅ Fetched \(response.count) remote + \(offlineMessages.count) offline messages")
            return combined.sorted { $0.createdAt > $1.createdAt }
        } catch {
            // Fallback to offline messages on error
            print("⚠️ Error fetching remote messages, returning offline only")
            return offlineStore.fetchAllMessages()
        }
    }
    
    /// Delete a message by ID (optional - for cleanup)
    /// - Parameter id: The message ID to delete
    func deleteMessage(id: Int) async throws {
        print("🗑️ Deleting message ID: \(id)")
        
        guard let client = client, !shouldUseOfflineMode else {
            print("📴 Cannot delete in offline mode")
            return
        }
        
        try await client
            .from("messages")
            .delete()
            .eq("id", value: id)
            .execute()
        
        print("✅ Message deleted")
    }
}

