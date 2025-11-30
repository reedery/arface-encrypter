//
//  ProfileView.swift
//  arface-encrypter
//
//  Created by ryan reede on 11/30/25.
//

import SwiftUI

struct ProfileView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "person.fill")
                    .imageScale(.large)
                    .font(.system(size: 60))
                    .foregroundStyle(.tint)
                
                Text("Demo User")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Always signed in for demo purposes")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .navigationTitle("Profile")
        }
    }
}

#Preview {
    ProfileView()
}
