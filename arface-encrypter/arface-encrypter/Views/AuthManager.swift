//
//  AuthManager.swift
//  arface-encrypter
//
//  Created by ryan reede on 11/30/25.
//

import Foundation
import Supabase
import Combine

@MainActor
class AuthManager: ObservableObject {
    @Published var session: Session?
    @Published var isLoading = true
    @Published var isExpired = false
    
    private var authStateTask: Task<Void, Never>?
    
    init() {
        setupAuthStateListener()
    }
    
    deinit {
        authStateTask?.cancel()
    }
    
    private func setupAuthStateListener() {
        authStateTask = Task {
            for await (event, session) in SupabaseConfig.shared.client.auth.authStateChanges {
                print("[AuthManager] Auth event: \(event), session exists: \(session != nil)")
                
                if event == .initialSession {
                    if let session {
                        if session.isExpired {
                            // Session exists but has been expired. It will try to refresh it in the background 
                            // and emit a `tokenRefresh` or `signOut` event depending on the result.
                            print("[AuthManager] Initial session is expired, waiting for refresh...")
                            self.session = nil
                            self.isExpired = true
                            self.isLoading = true
                        } else {
                            // Session exists and is valid, can let user in.
                            print("[AuthManager] Valid session found")
                            self.session = session
                            self.isExpired = false
                            self.isLoading = false
                        }
                    } else {
                        // Session does not exist, user needs to sign in
                        print("[AuthManager] No session found")
                        self.session = nil
                        self.isExpired = false
                        self.isLoading = false
                    }
                } else if event == .tokenRefreshed {
                    assert(session != nil && session?.isExpired == false)
                    print("[AuthManager] Token refreshed successfully")
                    self.session = session
                    self.isExpired = false
                    self.isLoading = false
                } else if event == .signedOut {
                    assert(session == nil)
                    print("[AuthManager] User signed out")
                    self.session = nil
                    self.isExpired = false
                    self.isLoading = false
                } else if event == .signedIn {
                    print("[AuthManager] User signed in")
                    self.session = session
                    self.isExpired = false
                    self.isLoading = false
                }
            }
        }
    }
    
    var isAuthenticated: Bool {
        session != nil && !isExpired
    }
    
    func signOut() async throws {
        try await SupabaseConfig.shared.client.auth.signOut()
    }
}
