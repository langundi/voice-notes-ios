//
//  DIContainer.swift
//  VoiceNotes
//
//  Created by Ziqa on 14/02/26.
//

import Foundation
import SwiftData

@MainActor
final class DIContainer {
    
    static let shared = DIContainer()
    private init() { }
    
    lazy var container: ModelContainer = makeContainer()
    lazy var audioRepository = AudioRepository(context: container.mainContext)
    lazy var audioManager = AudioManager()
    
    func makeHomeViewModel() -> HomeViewModel {
        HomeViewModel(audioRepository: audioRepository, audioManager: audioManager)
    }
    
    func makeRecordingViewModel() -> RecordingViewModel {
        RecordingViewModel(audioRepository: audioRepository)
    }
}

// MARK: - Swift Data Containers

extension DIContainer {
    
    // Container for simulators and devices
    func makeContainer() -> ModelContainer {
        let schema = Schema([
            AudioModel.self,
            FolderModel.self
        ])
        
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true
        )

        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
    
    // Container for preview
    func makePreviewContainer() -> ModelContainer {
        let schema = Schema([
            AudioModel.self,
            FolderModel.self
        ])
        
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true,
            allowsSave: true
        )
        
        let container = try! ModelContainer(for: schema, configurations: [configuration])
        
        let context = container.mainContext
        
        let recording1 = AudioModel(title: "New Recording 1", fileURL: dummyURL("recording1"), duration: 120)
        let recording2 = AudioModel(title: "New Recording 2", fileURL: dummyURL("recording2"), duration: 40)
        let recording3 = AudioModel(title: "New Recording 3", fileURL: dummyURL("recording3"), duration: 240)
        
        context.insert(recording1)
        context.insert(recording2)
        context.insert(recording3)
        
        return container
    }
    
    private func dummyURL(_ filename: String) -> URL {
        URL.documentsDirectory.appending(path: "\(filename).m4a")
    }
    
}
