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
    
    func makeHomeViewModel() -> HomeViewModel {
        HomeViewModel(audioRepository: audioRepository)
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

        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
    
}
