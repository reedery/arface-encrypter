//
//  ContentView.swift
//  arface-encrypter
//
//  Created by ryan reede on 11/30/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            EncodeView()
                .tabItem {
                    Label("Encode", systemImage: "lock.fill")
                }
            
            DecodeView()
                .tabItem {
                    Label("Decode", systemImage: "lock.open.fill")
                }
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
        }
    }
}

#Preview {
    ContentView()
}
