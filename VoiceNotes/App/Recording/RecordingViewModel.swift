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
    private var anyTranscriptionManager: Any?
    private(set) var transcriptionModel = TranscriptionModel()
    
    @available(iOS 26.0, *)
    private var transcriptionManager: TranscriptionManager? {
        anyTranscriptionManager as? TranscriptionManager
    }
    
    @available(iOS 26.0, *)
    init(audioRepository: AudioRepository, audioManager: AudioManager, transcriptionManager: TranscriptionManager? = nil) {
        self.audioRepository = audioRepository
        self.audioManager = audioManager
        self.anyTranscriptionManager = transcriptionManager
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
    
    func toggleSelection(for id: AudioModel.ID) {
        if selectedRecordings.contains(id) {
            selectedRecordings.remove(id)
        } else {
            selectedRecordings.insert(id)
        }
    }
    
    func dismissRecordingSheet() {
        showRecordingSheet = false
        currentTime = 0
        
        // Delay to compensate sheet closing animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.title = nil
            self.fileURL = nil
            self.createdAt = nil
        }
    }
    
    private func clearTranscript() {
        transcriptionModel.finalizedText = ""
        transcriptionModel.currentText = ""
    }
    
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
    
    // SAVING RECORDINGS
    func saveRecording() {
        audioRepository.addRecording(
            title: title!,
            fileName: fileURL!.lastPathComponent,
            duration: currentTime,
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
            duration: currentTime,
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
            duration: currentTime,
            createdAt: createdAt!,
            samples: samples,
            folder: folder!
        )
        
        audioManager.removeSamples()
    }
    
    
    // MOVING RECORDINGS FROM FOLDERS
    func moveRecordingToFolder(folder: FolderModel, recording: AudioModel) {
        stopAudio()
        audioRepository.moveRecordingToFolder(recording: recording, folder: folder)
    }
    
    func removeRecordingFromFolder(folder: FolderModel, recording: AudioModel) {
        stopAudio()
        audioRepository.removeRecordingFromFolder(recording: recording, folder: folder)
    }
    
    
    // DELETE RECORDING
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
    
    func toggleRecording() async {
        if hasStartedRecording {
            if isRecording {
                pauseRecording()
            } else {
                resumeRecording()
            }
        } else {
            await startRecording()
        }
    }
    
    func startRecording() async {
        guard !isRecording else { return }
        
        expandedRecording = nil
        showRecordingSheet = true
        
        let count = audioRepository.getAudioCount()
        
        title = "New Recording \(count)"
        fileURL = makeUniqueURL(for: title!)
        currentTime = 0
        recordingTime = 0
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
                        print("error transcribing: \(error.localizedDescription)")
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
        guard isRecording else { return }
        
        isRecording = false
        audioManager.pauseRecording()
        stopTimer()
        
        print("current = \(currentTime)")
        
//        setupPlaybackForCurrentlyRecording()
    }
    
    func resumeRecording() {
        guard !isRecording else { return }
        
        currentTime = recordingTime
        
        do {
            try audioManager.resumeRecording()
            isRecording = true
            startRecordingTimer()
        } catch {
            print("error resuming: \(error.localizedDescription)")
        }
    }
    
    func stopRecording() async {
        guard hasStartedRecording else {
            dismissRecordingSheet()
            return
        }
        
        isRecording = false
        hasStartedRecording = false
        
        stopTimer()
        
        audioManager.stopRecording()
        
        if #available(iOS 26.0, *) {
            await transcriptionManager?.stopTranscription()
            transcriptionModel.isRecording = false
            clearTranscript()
        }
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
    
    func setupPlaybackForCurrentlyRecording() {
        if isPlaying {
            stopAudio()
        }
        
        do {
            try audioManager.setupPlayback(fileURL: fileURL!, rate: 1.0)
            
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
