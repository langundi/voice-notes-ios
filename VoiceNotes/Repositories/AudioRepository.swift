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
    
    /// Creates a new folder
    func addNewFolder(title: String) {
        let newFolder = FolderModel(title: title)
        context.insert(newFolder)
        saveContext()
    }
    
    /// Deletes an existing folder
    func deleteFolder(folder: FolderModel) {
        context.delete(folder)
        saveContext()
    }
    
    /// Moves an existing recording to a folder
    func moveRecordingToFolder(recording: AudioModel, folder: FolderModel) {
        folder.Audios.append(recording)
        saveContext()
    }
    
    /// Removes an existing recording from a folder
    func removeRecordingFromFolder(recording: AudioModel, folder: FolderModel) {
        folder.Audios.removeAll { $0.id == recording.id }
        saveContext()
    }
    
    /// Returns a folder matching the name
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
    
    /// Creates a new recording
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
    
    func addRecordingToFolder(title: String, fileName: String, duration: Double, createdAt: Date, folder: FolderModel) {
        let recording = AudioModel(
            title: title,
            fileName: fileName,
            duration: duration,
            createdAt: createdAt
        )
        
        context.insert(recording)
        moveRecordingToFolder(recording: recording, folder: folder)
        saveContext()
    }
    
    /// Deletes existing recordings
    func deleteRecording(for recordings: [AudioModel]) {
        for recording in recordings {
            context.delete(recording)
        }
        saveContext()
    }
    
    /// Duplicates existing recording, modifes the title and the file directory
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
    
    /// Updates a recording's title
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
    
    /// Updates recording playback rate
    func updateRate(for audio: AudioModel, newRate: Float) {
        audio.rate = newRate
        saveContext()
    }
    
    /// Favorites a recording
    func favoriteRecording(for audio: AudioModel) {
        if audio.isFavorite {
            audio.isFavorite = false
        } else {
            audio.isFavorite = true
        }
        saveContext()
    }
    
    /// Returns the amount of all recordings
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
    
    /// Returns the latest recording based on date
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
