//
//  EncodeView.swift
//  arface-encrypter
//
//  Created by ryan reede on 11/30/25.
//

import SwiftUI

struct EncodeView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Image(systemName: "lock.fill")
                    .imageScale(.large)
                    .foregroundStyle(.tint)
                Text("Encode View")
            }
            .navigationTitle("Encode")
        }
    }
}

#Preview {
    EncodeView()
}
