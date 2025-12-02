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
    
    /// The Supabase client, nil if not configured
    let client: SupabaseClient?
    
    /// Whether Supabase is properly configured
    var isConfigured: Bool { client != nil }
    
    private init() {
        print("[SupabaseConfig] Init SupabaseClient")
        
        // Read from Info.plist to keep keys out of source code
        guard let supabaseURL = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String,
              !supabaseURL.isEmpty,
              supabaseURL != "YOUR_SUPABASE_URL" else {
            print("[SupabaseConfig] ⚠️ Missing or invalid SUPABASE_URL - running in offline-only mode")
            self.client = nil
            return
        }
        
        guard let supabaseKey = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String,
              !supabaseKey.isEmpty,
              supabaseKey != "YOUR_SUPABASE_ANON_KEY" else {
            print("[SupabaseConfig] ⚠️ Missing or invalid SUPABASE_ANON_KEY - running in offline-only mode")
            self.client = nil
            return
        }
        
        guard let url = URL(string: supabaseURL) else {
            print("[SupabaseConfig] ⚠️ Invalid SUPABASE_URL format: \(supabaseURL) - running in offline-only mode")
            self.client = nil
            return
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
