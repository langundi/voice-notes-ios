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
            print("error saving: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Folder
    
    func addNewFolder(title: String) {
        let newFolder = FolderModel(title: title)
        context.insert(newFolder)
        saveContext()
    }
    
    func deleteFolder(folder: FolderModel) {
        context.delete(folder)
        saveContext()
    }
    
    // MARK: - Recording 
    
    func addRecording(title: String, fileName: String, duration: Double, createdAt: Date) {
        let recording = AudioModel(
            title: title,
            fileName: fileName,
            duration: duration,
            createdAt: createdAt
        )
        
        context.insert(recording)
        saveContext()
    }
    
    func deleteRecording(for recordings: [AudioModel]) {
        for recording in recordings {
            context.delete(recording)
        }
        saveContext()
    }
    
    func duplicateRecording(from audio: AudioModel, newFile fileName: String) {
        let newTitle = audio.title + " copy"
        let newDate = Date.now
        let recording = AudioModel(
            title: newTitle,
            fileName: fileName,
            duration: audio.duration,
            createdAt: newDate
        )
        
        context.insert(recording)
        saveContext()
    }
    
    func updateTitle(for audio: AudioModel, newTitle: String) {
        audio.title = newTitle
        saveContext()
    }
    
    func getAudioCount() -> Int {
        let sortByDate = [SortDescriptor(\AudioModel.createdAt, order: .reverse)]
        let descriptor = FetchDescriptor<AudioModel>(sortBy: sortByDate)
        
        do {
            return try context.fetchCount(descriptor) + 1
        } catch {
            print("error getting count: \(error.localizedDescription)")
            return 0
        }
    }
}
