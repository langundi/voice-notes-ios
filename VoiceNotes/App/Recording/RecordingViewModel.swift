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
    
    private(set) var transcriptionModel = TranscriptionModel()
    private var transcriptionProvder: Any?
    
    @available(iOS 26.0, *)
    private var transcriptionManager: TranscriptionManager? {
        transcriptionProvder as? TranscriptionManager
    }
    
    @available(iOS 26.0, *)
    init(audioRepository: AudioRepository, audioManager: AudioManager, transcriptionManager: TranscriptionManager? = nil) {
        self.audioRepository = audioRepository
        self.audioManager = audioManager
        self.transcriptionProvder = transcriptionManager
    }
    
    init(audioRepository: AudioRepository, audioManager: AudioManager) {
        self.audioRepository = audioRepository
        self.audioManager = audioManager
    }
    
    deinit {
        resetUI()
    }
    
    // Recording Sheet and Row Properties
    var title: String?
    var fileURL: URL?
    var finalizedURL: URL?
    var mergedFileURL: URL?
    var segmentsURLs: [URL] = []
    var createdAt: Date?
    var timer: Timer?
    var currentTime: TimeInterval = 0
    var recordingTimer: Timer?
    var recordingTime: TimeInterval = 0
    var countdown: TimeInterval {
        max(0, audioManager.totalDuration - currentTime)
    }
    
    // Recording Screen Properties
    var hasStartedRecording: Bool = false
    var hasStartedPlaying: Bool = false
    var showRecordingSheet: Bool = false
    var isRecording: Bool = false
    var isPlaying: Bool = false
    var isEditing: Bool = false {
        didSet {
            if !isEditing {
                selectedRecordings.removeAll()
            }
        }
    }
    var hideRecordButton = false
    var isScrubbing = false
    var wasPlayingBeforeScrub = false
    var samples: [Float] {
        audioManager.samples
    }
    
    var selectedRecordings: Set<AudioModel.ID> = []
    var expandedRecording: AudioModel.ID? = nil
    
    // Options Sheet Properties
    var showOptionsSheet: Bool = false
    var rate: Float = 1
    var defaultSettings: Bool = true
    
    // Select Folder Sheet Properties
    var showSelectFolderSheet: Bool = false
    
    func resetUI() {
        hasStartedRecording = false
        hasStartedPlaying = false
        isRecording = false
        isPlaying = false
        isEditing = false
        isScrubbing = false
        wasPlayingBeforeScrub = false
        currentTime = 0
    }
    
    func dismissRecordingSheet() {
        showRecordingSheet = false
        hasStartedPlaying = false
        hasStartedRecording = false
        isRecording = false
        isPlaying = false
        isScrubbing = false
        currentTime = 0
        recordingTime = 0
        clearTranscript()
        
        // Delay to compensate sheet closing animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.title = nil
            self.fileURL = nil
            self.createdAt = nil
        }
    }
    
    func toggleSelection(for id: AudioModel.ID) {
        if selectedRecordings.contains(id) {
            selectedRecordings.remove(id)
        } else {
            selectedRecordings.insert(id)
        }
    }
    
    private func clearTranscript() {
        transcriptionModel.finalizedText = ""
        transcriptionModel.currentText = ""
    }
    
    private func startRecordingTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.currentTime += 0.01
        }
        
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.recordingTime += 0.01
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
        
        recordingTimer?.invalidate()
        recordingTimer = nil
    }
}


// MARK: - Data

extension RecordingViewModel {
    
    // Save recordings
    func saveRecording() {
        audioRepository.addRecording(
            title: title!,
            fileName: fileURL!.lastPathComponent,
            duration: recordingTime,
            createdAt: createdAt!,
            transcript: transcriptionModel.displayText,
            samples: samples
        )
        
        audioManager.removeSamples()
    }
    
    func saveRecordingForFavorites() {
        audioRepository.addRecording(
            title: title!,
            fileName: fileURL!.lastPathComponent,
            duration: recordingTime,
            createdAt: createdAt!,
            isFavorite: true,
            samples: samples
        )
        
        audioManager.removeSamples()
    }
    
    func saveRecordingToFolder(folderTitle: String) {
        let folder = audioRepository.getFolderByName(title: folderTitle).first
        
        audioRepository.addRecordingToFolder(
            title: title!,
            fileName: fileURL!.lastPathComponent,
            duration: recordingTime,
            createdAt: createdAt!,
            samples: samples,
            folder: folder!
        )
        
        audioManager.removeSamples()
    }
    
    
    // Move recordings
    func moveRecordingToFolder(folder: FolderModel, recording: AudioModel) {
        stopAudio()
        audioRepository.moveRecordingToFolder(recording: recording, folder: folder)
    }
    
    func removeRecordingFromFolder(folder: FolderModel, recording: AudioModel) {
        stopAudio()
        audioRepository.removeRecordingFromFolder(recording: recording, folder: folder)
    }
    
    
    // Delete Recordings
    func deleteRecording(for recordings: [AudioModel]) {
        stopAudio()
        audioRepository.deleteRecording(for: recordings)
        expandedRecording =  nil
    }
    
    func moveToTrash(for recordings: [AudioModel]) {
        stopAudio()
        audioRepository.moveToTrash(for: recordings)
        expandedRecording = nil
    }
    
    func recoverRecordings(for recordings: [AudioModel]) {
        stopAudio()
        audioRepository.recoverRecordings(for: recordings)
        expandedRecording = nil
    }
    
    
    // Update recordings attribute
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

    
    // Duplicate recordings
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
    
    func toggleRecording() async {
        if hasStartedRecording {
            if isRecording {
                await pauseAndMergeRecording()
            } else {
                await resumeRecording()
            }
        } else {
            await startRecording()
        }
    }
    
    func startRecording() async {
        guard !isRecording else { return }
        
        showRecordingSheet = true
        
        let count = audioRepository.getAudioCount()
        
        title = "New Recording \(count)"
        fileURL = makeSegmentURL()
        createdAt = Date.now
        
        do {
            if #available(iOS 26.0, *) {
                try await transcriptionManager!.startTranscription { [weak self] text, isFinal in
                    Task { @MainActor in
                        guard let self = self else { return }
                        if isFinal {
                            
                            // Prevent double space after .
                            if self.transcriptionModel.finalizedText.contains(".") {
                                self.transcriptionModel.finalizedText += text
                            } else {
                                self.transcriptionModel.finalizedText += text + " "
                            }
                            
                            self.transcriptionModel.currentText = ""
                        } else {
                            self.transcriptionModel.currentText = text
                        }
                    }
                }
                
                try audioManager.startRecording(for: fileURL!) { [weak self] buffer in
                    guard let self else { return }
                    
                    // Transcribe buffer
                    do {
                        try self.transcriptionManager!.processAudioBuffer(buffer)
                    } catch {
                        print("Error transcribing: \(error.localizedDescription)")
                    }
                    
                    transcriptionModel.isRecording = true
                }
            } else {
                try audioManager.startRecording(for: fileURL!) { [weak self] buffer in
                    guard self != nil else { return }
                    
                }
            }
            
            audioManager.onRecordingFinished = { [weak self] _ in
                guard let self else { return }
                
                expandedRecording = nil
                
                if let newRecording = audioRepository.getLatestRecording().first {
                    expandedRecording = newRecording.id
                    setupPlayback(for: newRecording)
                }
            }
            
            hasStartedRecording = true
            isRecording = true
            startRecordingTimer()
        } catch {
            print("Error start recording: \(error.localizedDescription)")
        }
    }
    
//    func pauseRecording() {
//        guard isRecording else { return }
//        
//        isRecording = false
//        audioManager.pauseRecording()
//        stopTimer()
//    }
    
    func pauseAndMergeRecording() async {
        guard isRecording, let currentFileURL = fileURL else { return }
        
        audioManager.stopRecording()
        
        if #available(iOS 26.0, *) {
            await transcriptionManager?.stopTranscription()
            transcriptionModel.isRecording = false
        }
        
        isRecording = false
        stopTimer()
        
        if finalizedURL == nil {
            finalizedURL = currentFileURL
            
            // Insert current URL into an array for merging and setup for playback
            segmentsURLs.append(currentFileURL)
            setupPlaybackForPausedRecording(url: currentFileURL)
            
            fileURL = nil
        } else {
            segmentsURLs.append(currentFileURL)
            
            do {
                let newURL = makeSegmentURL()
                
                // Merging all segments to new URL
                try await audioManager.mergeSegments(segmentsURLs, into: newURL)
                
                // Setup playback for the new merged URL
                setupPlaybackForPausedRecording(url: newURL)
                finalizedURL = newURL
                
                // Reset segment array
                segmentsURLs = [newURL]
                fileURL = nil
            } catch {
                print("Error merging segments: \(error.localizedDescription)")
            }
        }
    }
    
    func resumeRecording() async {
        guard !isRecording else { return }
        
        if isPlaying {
            stopAudio()
        }
        
        currentTime = recordingTime
        
        await startRecording()
    }
    
    func stopRecording() async throws {
        guard hasStartedRecording, let currentFileURL = fileURL else {
            dismissRecordingSheet()
            return
        }
        
        audioManager.stopRecording()
        stopTimer()
        
        let finalURL = makeUniqueURL(for: title!)
        
        // Merge or replace URL with final URL
        if isRecording {
            segmentsURLs.append(currentFileURL)
            try await audioManager.mergeSegments(segmentsURLs, into: finalURL)
            fileURL = finalURL
        } else {
            if let source = finalizedURL {
                try moveURL(from: source, to: finalURL)
                fileURL = finalURL
            }
        }
        
        if #available(iOS 26.0, *) {
            await transcriptionManager?.stopTranscription()
            transcriptionModel.isRecording = false
        }
        
        isRecording = false
        hasStartedRecording = false
        segmentsURLs.removeAll()
        finalizedURL = nil
    }
    
    func stopAndSave(folderTitle: String) async {
        do {
            try await stopRecording()
            
            if folderTitle == "Favorites" {
                saveRecordingForFavorites()
            } else if folderTitle == "All Recordings" {
                saveRecording()
            } else {
                saveRecordingToFolder(folderTitle: folderTitle)
            }
            
            dismissRecordingSheet()
        } catch {
            print("Failed to stop and save: \(error.localizedDescription)")
        }
    }
    
}


// MARK: - Playback

extension RecordingViewModel {
    
    func setupPlayback(for recording: AudioModel) {
        if isPlaying {
            stopAudio()
        }
        
        fileURL = getURL(for: recording.fileName)
        
        do {
            try audioManager.setupPlayback(fileURL: fileURL!, rate: recording.rate)
            
            audioManager.onPlaybackFinished = { [weak self] _ in
                DispatchQueue.main.async {
                    self?.hasStartedPlaying = false
                    self?.isScrubbing = false
                    self?.isPlaying = false
                    self?.currentTime = 0
                    self?.stopTimer()
                }
            }
        } catch {
            print("error setup playback: \(error.localizedDescription)")
        }
    }
    
    private func setupPlaybackForPausedRecording(url: URL) {
        do {
            try audioManager.setupPlayback(fileURL: url, rate: 1.0)
            
            audioManager.onPlaybackFinished = { [weak self] _ in
                DispatchQueue.main.async {
                    self?.hasStartedPlaying = false
                    self?.isScrubbing = false
                    self?.isPlaying = false
                    self?.currentTime = 0
                    self?.stopTimer()
                }
            }
        } catch {
            print("Error playback setup when paused: \(error)")
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
        currentTime = 0
    }
    
    func play(at time: TimeInterval) {
        audioManager.seek(to: currentTime)
        hasStartedPlaying = true
        isPlaying = true
    }
    
    func startScrubbing() {
        guard !isScrubbing else { return }
        
        isScrubbing = true
        wasPlayingBeforeScrub = isPlaying
        
        // Pause playback while scrubbing
        if isPlaying {
            pauseAudio()
        }
    }
    
    func endScrubbing() {
        guard isScrubbing else { return }
        
        isScrubbing = false
        
        // Seek to the final position
        audioManager.seek(to: currentTime)
        
        // Resume playback if it was playing before
        if wasPlayingBeforeScrub {
            resumeAudio()
        }
    }
    
    func updateScrubbingPosition(to time: TimeInterval) {
        // Update UI, not seek yet
        currentTime = time
    }
    
    func rewind15Seconds() {
        let newTime = currentTime - 15
        currentTime = newTime
        
        audioManager.seek(to: newTime)
    }
    
    func forward15Seconds() {
        let newTime = currentTime + 15
        currentTime = newTime
        
        audioManager.seek(to: newTime)
    }
    
    func changeRate(to rate: Float) {
        audioManager.updateRate(to: rate)
    }
    
    func resetPlaybackOptions(for recording: AudioModel) {
        rate = 1.0
        audioManager.updateRate(to: rate)
        audioRepository.updateRate(for: recording, newRate: rate)
    }
    
    private func stopPlaybackIfNeeded() {
        guard isPlaying else { return }
        stopAudio()
    }
}
