//
//  SupabaseConfig.swift
//  arface-encrypter
//
//  Created by ryan reede on 11/30/25.
//

import Foundation
import Supabase

class SupabaseConfig {
    static let shared = SupabaseConfig()
    
    let client: SupabaseClient
    
    private init() {
        print("[SupabaseConfig] Init SupabaseClient")
        
        // Read from Info.plist to keep keys out of source code
        guard let supabaseURL = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String else {
            fatalError("Missing SUPABASE_URL in Info.plist")
        }
        
        guard let supabaseKey = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String else {
            fatalError("Missing SUPABASE_ANON_KEY in Info.plist")
        }
        
        guard let url = URL(string: supabaseURL) else {
            fatalError("Invalid SUPABASE_URL format: \(supabaseURL)")
        }
        
        print("[SupabaseConfig] URL: \(supabaseURL)")
        print("[SupabaseConfig] Key length: \(supabaseKey.count)")
        
        // Configure JSON decoder for ISO8601 dates
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
                
        self.client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: supabaseKey,
            options: SupabaseClientOptions(
                auth: SupabaseClientOptions.AuthOptions(
                    emitLocalSessionAsInitialSession: true
                )
            )
        )
        
        print("[SupabaseConfig] Client initialized successfully")
    }
}
