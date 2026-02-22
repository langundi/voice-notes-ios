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
        RecordingViewModel(audioRepository: audioRepository, audioManager: audioManager)
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
        
        let folder1 = FolderModel(title: "Folder 1")
        
        let now = Date.now
        let formattedDate = formatDate(date: now, format: "HH:mm:ss_dd MMM yyyy")
        
        let recording1 = AudioModel(title: "Asdf_\(formattedDate)", fileName: "New Recording 1.m4a", duration: 120, createdAt: now)
        let recording2 = AudioModel(title: "Qwer_\(formattedDate)", fileName: "New Recording 1.m4a", duration: 40, createdAt: now)
        let recording3 = AudioModel(title: "Uiop_\(formattedDate)", fileName: "New Recording 1.m4a", duration: 240, createdAt: now)
        let recording4 = AudioModel(title: "Not in a folder_\(formattedDate)", fileName: "New Recording 1.m4a", duration: 120, createdAt: now)
        
        recording1.isFavorite = true
        recording3.isFavorite = true
        
        let recordings = [recording1, recording2, recording3]
        
        folder1.Audios = recordings
        
        context.insert(folder1)
        context.insert(recording4)
        
        return container
    }
    
}
