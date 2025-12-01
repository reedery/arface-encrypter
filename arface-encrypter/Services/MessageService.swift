//
//  MessageService.swift
//  arface-encrypter
//
//  Created by Claude Code
//

import Foundation
import Supabase

/// Service for managing messages in Supabase
class MessageService {
    static let shared = MessageService()
    
    private let client = SupabaseConfig.shared.client
    
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
    
    // MARK: - Public Methods
    
    /// Create a new message in the database
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
    }
    
    /// Fetch a message by its expression hash
    /// - Parameter hash: The expression hash to search for
    /// - Returns: The matching message or nil if not found
    func fetchMessage(byHash hash: String) async throws -> Message? {
        print("🔍 Fetching message with hash: \(hash)")
        
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
        
        let response: [Message] = try await client
            .from("messages")
            .select()
            .order("created_at", ascending: false)
            .execute()
            .value
        
        print("✅ Fetched \(response.count) messages")
        return response
    }
    
    /// Delete a message by ID (optional - for cleanup)
    /// - Parameter id: The message ID to delete
    func deleteMessage(id: Int) async throws {
        print("🗑️ Deleting message ID: \(id)")
        
        try await client
            .from("messages")
            .delete()
            .eq("id", value: id)
            .execute()
        
        print("✅ Message deleted")
    }
}

