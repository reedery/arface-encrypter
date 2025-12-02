//
//  OfflineMessageStore.swift
//  arface-encrypter
//
//  Local storage for offline mode messages
//

import Foundation

/// Manages local storage of messages when in offline mode
class OfflineMessageStore {
    static let shared = OfflineMessageStore()
    
    private let storageKey = "offlineMessages"
    private var nextID: Int = 1
    
    /// Local message structure (matches Message but with local ID generation)
    struct OfflineMessage: Codable, Identifiable {
        let id: Int
        let createdAt: Date
        let expressionHash: String
        let message: String
        let expressionList: String
    }
    
    private init() {
        // Find the highest existing ID to continue from
        if let messages = loadMessages(), let maxID = messages.map({ $0.id }).max() {
            nextID = maxID + 1
        }
    }
    
    // MARK: - Public Methods
    
    /// Save a new message locally
    func saveMessage(expressionHash: String, message: String, expressionList: String) -> Message {
        var messages = loadMessages() ?? []
        
        let offlineMessage = OfflineMessage(
            id: nextID,
            createdAt: Date(),
            expressionHash: expressionHash,
            message: message,
            expressionList: expressionList
        )
        
        messages.append(offlineMessage)
        nextID += 1
        
        saveMessages(messages)
        print("💾 Saved offline message with ID: \(offlineMessage.id)")
        
        // Convert to Message type for compatibility
        return convertToMessage(offlineMessage)
    }
    
    /// Fetch a message by expression hash
    func fetchMessage(byHash hash: String) -> Message? {
        guard let messages = loadMessages() else { return nil }
        
        if let offlineMessage = messages.first(where: { $0.expressionHash == hash }) {
            print("📖 Found offline message with hash: \(hash)")
            return convertToMessage(offlineMessage)
        }
        
        print("❌ No offline message found with hash: \(hash)")
        return nil
    }
    
    /// Fetch all offline messages
    func fetchAllMessages() -> [Message] {
        guard let messages = loadMessages() else { return [] }
        return messages.map { convertToMessage($0) }
    }
    
    /// Get count of offline messages
    func messageCount() -> Int {
        return loadMessages()?.count ?? 0
    }
    
    /// Clear all offline messages
    func clearAllMessages() {
        UserDefaults.standard.removeObject(forKey: storageKey)
        nextID = 1
        print("🗑️ Cleared all offline messages")
    }
    
    // MARK: - Private Methods
    
    private func loadMessages() -> [OfflineMessage]? {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else {
            return nil
        }
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode([OfflineMessage].self, from: data)
        } catch {
            print("❌ Failed to decode offline messages: \(error)")
            return nil
        }
    }
    
    private func saveMessages(_ messages: [OfflineMessage]) {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(messages)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            print("❌ Failed to encode offline messages: \(error)")
        }
    }
    
    private func convertToMessage(_ offline: OfflineMessage) -> Message {
        return Message(
            id: offline.id,
            createdAt: offline.createdAt,
            expressionHash: offline.expressionHash,
            message: offline.message,
            expressionList: offline.expressionList
        )
    }
}

