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
    
    func getFolderByName(title: String) -> [FolderModel] {
        let predicate = #Predicate<FolderModel> { $0.title == title }
        var descriptor = FetchDescriptor(predicate: predicate)
        descriptor.fetchLimit = 1
        
        do {
            return try context.fetch(descriptor)
        } catch {
            print("error fetching folder: \(error.localizedDescription)")
            return []
        }
    }
    
    // MARK: - Recording 
    
    func addRecording(title: String, fileName: String, duration: Double, createdAt: Date, isFavorite: Bool = false) {
        let recording = AudioModel(
            title: title,
            fileName: fileName,
            duration: duration,
            createdAt: createdAt
        )
        recording.isFavorite = isFavorite

        context.insert(recording)
        saveContext()
    }
    
    func addRecordingToFolder(folder: FolderModel, recording: AudioModel) {
        folder.Audios.append(recording)
        
        saveContext()
    }
    
    func deleteRecording(for recordings: [AudioModel]) {
        for recording in recordings {
            context.delete(recording)
        }
        saveContext()
    }
    
    func duplicateRecording(from audio: AudioModel, newFile fileName: String) {
        let newTitle = "Copy of " + audio.title
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
        guard audio.title != newTitle else { return }
        
        let oldURL = getURL(for: audio.fileName)
        let newURL = makeUniqueURL(for: newTitle)
        
        do {
            try FileManager.default.moveItem(at: oldURL, to: newURL)
            audio.title = newTitle
            audio.fileName = newURL.lastPathComponent
            
            saveContext()
        } catch {
            print("error updating title: \(error.localizedDescription)")
        }
    }
    
    func updateRate(for audio: AudioModel, newRate: Float) {
        audio.rate = newRate
        saveContext()
    }
    
    func favoriteRecording(for audio: AudioModel) {
        if audio.isFavorite {
            audio.isFavorite = false
        } else {
            audio.isFavorite = true
        }
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
    
    func getLatestRecording() -> [AudioModel] {
        let sortByDate = [SortDescriptor(\AudioModel.createdAt, order: .reverse)]
        var descriptor = FetchDescriptor<AudioModel>(sortBy: sortByDate)
        descriptor.fetchLimit = 1
        
        do {
            return try context.fetch(descriptor)
        } catch {
            print("error fetching latest: \(error.localizedDescription)")
            return []
        }
    }
}
