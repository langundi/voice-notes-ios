//
//  VoiceNotesApp.swift
//  VoiceNotes
//
//  Created by Ziqa on 13/02/26.
//

import SwiftUI
import SwiftData

@main
struct VoiceNotesApp: App {
    
    private let container = DIContainer.shared.container
    
    @Environment(\.undoManager) var undoManager

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}
