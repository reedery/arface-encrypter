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
    
    /// Memberwise initializer for creating messages locally (offline mode)
    init(id: Int, createdAt: Date, expressionHash: String?, message: String?, expressionList: String?) {
        self.id = id
        self.createdAt = createdAt
        self.expressionHash = expressionHash
        self.message = message
        self.expressionList = expressionList
    }

    /// Computed property to convert expression_list string to array of FaceExpression enums
    var expressions: [FaceExpression]? {
        guard let expressionList = expressionList else { return nil }
        return expressionList.split(separator: ",")
            .compactMap { FaceExpression(rawValue: String($0)) }
    }
}
