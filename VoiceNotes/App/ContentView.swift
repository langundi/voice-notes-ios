//
//  ContentView.swift
//  VoiceNotes
//
//  Created by Ziqa on 13/02/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationStack {
            HomeScreen()
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(DIContainer.shared.container)
}
