//
//  AudioRepository.swift
//  VoiceNotes
//
//  Created by Ziqa on 14/02/26.
//

import Foundation
import SwiftData

final class AudioRepository {
    
    private let context: ModelContext
    
    init(context: ModelContext) {
        self.context = context
    }
    
    private func saveContext() {
        do {
            if context.hasChanges {
                try context.save()
            }
        } catch {
            print("Database Error: \(error)")
        }
    }
    
    // MARK: - Folder Functions
    
    func addNewFolder(title: String) {
        let newFolder = FolderModel(title: title)
        context.insert(newFolder)
        saveContext()
    }
    
    func deleteFolder(folder: FolderModel) {
        context.delete(folder)
        saveContext()
    }
    
    // MARK: - Recording Functions
    
    func addRecording(fileURL: URL, duration: Double) {
        let recording = AudioModel(
            title: "New recording",
            fileURL: fileURL,
            duration: duration
        )
        
        recording.createdAt = Date.now
        
        do {
            context.insert(recording)
            try context.save()
        } catch {
            print("Error saving recording: \(error.localizedDescription)")
        }
    }
    
}
