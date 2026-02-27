//
//  RecordingViewModel.swift
//  VoiceNotes
//
//  Created by Ziqa on 14/02/26.
//

import Foundation
import SwiftData

@Observable
final class RecordingViewModel {
    
    private let audioRepository: AudioRepository
    private let audioManager: AudioManager
    
    init(audioRepository: AudioRepository, audioManager: AudioManager) {
        self.audioRepository = audioRepository
        self.audioManager = audioManager
    }
    
    deinit {
        resetUI()
    }
    
    var title: String?
    var fileURL: URL?
    var createdAt: Date?
    var timer: Timer?
    var currentTime: TimeInterval = 0
    
    // Recording Screen Properties
    var hasStartedRecording: Bool = false
    var hasStartedPlaying: Bool = false
    var isRecording: Bool = false
    var isPlaying: Bool = false
    var isEditing: Bool = false {
        didSet {
            if !isEditing {
                selectedRecordings.removeAll()
//                selectedRow.removeAll()
            }
        }
    }
    var selectedRecordings: Set<AudioModel.ID> = []
    var selectedRow: [RowModel] = []
    var rowItems: [RowModel] = []
    var expandedRecording: AudioModel.ID? = nil
    
    // Options Sheet Properties
    var showOptionsSheet: Bool = false
    var rate: Float = 1
    var skipSilenceOn: Bool = false
    var enhanceRecordingOn: Bool = false
    var defaultSettings: Bool = true
    
    // Select Foldet Sheet Properties
    var showSelectFolderSheet: Bool = false
    
    func resetUI() {
        hasStartedRecording = false
        hasStartedPlaying = false
        isRecording = false
        isPlaying = false
        isEditing = false
        currentTime = 0
    }
    
    func syncItems(recordings: [AudioModel]) {
        let existingIDs = Set(rowItems.map(\.id))
        
        for recording in recordings {
            if !existingIDs.contains(recording.id) {
                rowItems.append(RowModel(id: recording.id, recording: recording))
            }
        }
    }
    
    func dismissRecordingSheet() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.title = nil
            self.fileURL = nil
            self.currentTime = 0
            self.createdAt = nil
        }
    }
    
//    func dismissOptionsSheet() {
//        showOptionsSheet = false
//    }
    
    func toggleSelection(for id: AudioModel.ID) {
        if selectedRecordings.contains(id) {
            selectedRecordings.remove(id)
        } else {
            selectedRecordings.insert(id)
        }
    }
    
//    func toggleRowSelection(for row: RowModel) {
//        if selectedRow.contains(row) {
//            selectedRow.removeAll { $0.id == row.id }
//        } else {
//            selectedRow.append(row)
//        }
//    }
    
    private func duplicateFile(sourceURL: URL, destinationURL: URL) {
        let fileManager = FileManager.default
        
        let destinationDirectory = destinationURL.deletingLastPathComponent()
        if !fileManager.fileExists(atPath: destinationDirectory.path) {
            do {
                try fileManager.createDirectory(at: destinationURL, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("error creating directory: \(error.localizedDescription)")
                return
            }
        }
        
        do {
            try fileManager.copyItem(at: sourceURL, to: destinationURL)
        } catch {
            print("error duplicating file: \(error.localizedDescription)")
        }
    }
    
    private func startRecordingTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.currentTime = self.audioManager.currentRecordingTime
        }
    }
    
    private func startPlaybackTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.currentTime = self.audioManager.currentPlaybackTime
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
}


// MARK: - Data

extension RecordingViewModel {
    
    // SAVING RECORDINGS
    func saveRecording() {
        audioRepository.addRecording(
            title: title!,
            fileName: fileURL!.lastPathComponent,
            duration: currentTime,
            createdAt: createdAt!
        )
    }
    
    func saveRecordingForFavorites() {
        audioRepository.addRecording(
            title: title!,
            fileName: fileURL!.lastPathComponent,
            duration: currentTime,
            createdAt: createdAt!,
            isFavorite: true
        )
    }
    
    func saveRecordingToFolder(folderTitle: String) {
        let folder = audioRepository.getFolderByName(title: folderTitle).first
        
        audioRepository.addRecordingToFolder(
            title: title!,
            fileName: fileURL!.lastPathComponent,
            duration: currentTime,
            createdAt: createdAt!,
            folder: folder!
        )
    }
    
    
    // MOVING RECORDINGS FROM FOLDERS
    func moveRecordingToFolder(folder: FolderModel, recording: AudioModel) {
        audioRepository.moveRecordingToFolder(recording: recording, folder: folder)
    }
    
    func removeRecordingFromFolder(folder: FolderModel, recording: AudioModel) {
        audioRepository.removeRecordingFromFolder(recording: recording, folder: folder)
    }
    
    
    // DELETE RECORDING
    func deleteRecording(from recordings: [AudioModel]) {
        for recording in recordings {
            rowItems.removeAll { $0.id == recording.id }
        }
        audioRepository.deleteRecording(for: recordings)
        expandedRecording =  nil
    }
    
    
    // UPDATE RECORDINGS ATTRIBUTE
    func renameTitle(for recording: AudioModel, newTitle: String) {
        audioRepository.updateTitle(for: recording, newTitle: newTitle)
    }
    
    func updateRate(for recording: AudioModel, newRate: Float) {
        audioRepository.updateRate(for: recording, newRate: newRate)
    }
    
    func updateOptionsState(for recording: AudioModel) {
        rate = recording.rate
    }
    
    func favoriteRecording(recording: AudioModel) {
        audioRepository.favoriteRecording(for: recording)
    }
    
    
    // DUPLICATE RECORDING
    func duplicateRecording(recording: AudioModel) {
        let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let sourceFile = path.appending(path: recording.fileName)
        let copiedFileName = "Copy of " + recording.fileName
        let destinationFile = path.appending(path: copiedFileName)
        
        duplicateFile(sourceURL: sourceFile, destinationURL: destinationFile)
        
        audioRepository.duplicateRecording(from: recording, newFile: copiedFileName)
    }
}


// MARK: - Recording

extension RecordingViewModel {
    
    func toggleRecording() {
        if hasStartedRecording {
            if isRecording {
                pauseRecording()
            } else {
                resumeRecording()
            }
        } else {
            startRecording()
        }
    }
    
    func startRecording() {
        let count = audioRepository.getAudioCount()
        
        title = "New Recording \(count)"
        fileURL = makeUniqueURL(for: title!)
        currentTime = 0
        createdAt = Date.now
        
        do {
            try audioManager.startRecording(fileURL: fileURL!)
            
            audioManager.onRecordingFinished = { [weak self] _ in
                guard let self else { return }
                
                hasStartedRecording = false
                isRecording = false
                
                // Set expanded row to most latest recording
                expandedRecording = nil
                if let newRecording = audioRepository.getLatestRecording().first {
                    expandedRecording = newRecording.id
                    
                    // Setup playback
                    setupPlayback(for: newRecording)
                }
            }
            
            hasStartedRecording = true
            isRecording = true
            
            startRecordingTimer()
        } catch {
            print("error start recording: \(error.localizedDescription)")
        }
    }
    
    func pauseRecording() {
        isRecording = false
        audioManager.pauseRecording()
        stopTimer()
    }
    
    func resumeRecording() {
        isRecording = true
        audioManager.resumeRecording()
        startRecordingTimer()
    }
    
    func stopRecording() {
        isRecording = false
        hasStartedRecording = false
        
        stopTimer()
        audioManager.stopRecording()
    }
}


// MARK: - Playback

extension RecordingViewModel {
    
    // Setup playback when a row is expanded
    func setupPlayback(for recording: AudioModel) {
        if isPlaying {
            stopAudio()
        }
        
        fileURL = getURL(for: recording.fileName)
        
        do {
            try audioManager.setupPlayback(fileURL: fileURL!, rate: recording.rate)
            
            audioManager.onPlaybackFinished = { [weak self] _ in
                self?.hasStartedPlaying = false
                self?.isPlaying = false
                self?.currentTime = 0
                self?.stopTimer()
            }
        } catch {
            print("error setup playback: \(error.localizedDescription)")
        }
    }
    
    func togglePlayback() {
        if hasStartedPlaying {
            if isPlaying {
                pauseAudio()
            } else {
                resumeAudio()
            }
        } else {
            startAudio()
        }
    }
    
    func startAudio() {
        do {
            try audioManager.startPlayback()
            
            startPlaybackTimer()
            
            hasStartedPlaying = true
            isPlaying = true
        } catch {
            print("error playing audio: \(error.localizedDescription)")
        }
    }
    
    func pauseAudio() {
        audioManager.pausePlayback()
        stopTimer()
        isPlaying = false
    }
    
    func resumeAudio() {
        audioManager.resumePlayback()
        startPlaybackTimer()
        isPlaying = true
    }
    
    func stopAudio() {
        audioManager.stopPlayback()
        stopTimer()
        fileURL = nil
        hasStartedPlaying = false
        isPlaying = false
    }
    
    func play(at time: TimeInterval) {
        audioManager.play(at: time)
        isPlaying = true
    }
    
    func rewind15Seconds() {
        let newTime = currentTime - 15
        currentTime = newTime
        
        do {
            try audioManager.seek(at: newTime)
        } catch {
            print("error seeking: \(error.localizedDescription)")
        }
    }
    
    func forward15Seconds() {
        let newTime = currentTime + 15
        currentTime = newTime
        
        do {
            try audioManager.seek(at: newTime)
        } catch {
            print("error seeking: \(error.localizedDescription)")
        }
    }
    
    func changeRate(to rate: Float) {
        audioManager.updateRate(to: rate)
    }
    
    func resetPlaybackOptions(for recording: AudioModel) {
        let rate: Float = 1.0
        audioManager.updateRate(to: rate)
        audioRepository.updateRate(for: recording, newRate: rate)
    }
}
