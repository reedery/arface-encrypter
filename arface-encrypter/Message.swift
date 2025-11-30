//
//  Message.swift
//  arface-encrypter
//
//  Created by ryan reede on 11/30/25.
//

import Foundation

struct Message: Codable, Identifiable {
    let id: Int
    let createdAt: Date
    let expressionHash: String?
    let message: String?
    let expressionList: String?
    
    // Map snake_case from Supabase to camelCase in Swift
    enum CodingKeys: String, CodingKey {
        case id
        case createdAt = "created_at"
        case expressionHash = "expression_hash"
        case message
        case expressionList = "expression_list"
    }
}
