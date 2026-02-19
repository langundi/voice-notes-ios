//
//  RecordingViewModel.swift
//  VoiceNotes
//
//  Created by Ziqa on 14/02/26.
//

import Foundation
import SwiftUI

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
    
    // UI Attributes
    var hasStartedRecording: Bool = false
    var hasStartedPlaying: Bool = false
    var isRecording: Bool = false
    var isPlaying: Bool = false
    var isEditing: Bool = false {
        didSet {
            if !isEditing {
                selectedRecordings.removeAll()
            }
        }
    }
    var showSheet: Bool = false
    var expandedRecording: AudioModel.ID? = nil
    var selectedRecordings: Set<AudioModel.ID> = []
    
    func resetUI() {
        hasStartedRecording = false
        hasStartedPlaying = false
        isRecording = false
        isPlaying = false
        isEditing = false
        showSheet = false
        currentTime = 0
    }
    
    func toggleSelection(for id: AudioModel.ID) {
        if selectedRecordings.contains(id) {
            selectedRecordings.remove(id)
        } else {
            selectedRecordings.insert(id)
        }
    }
    
    func getFormattedDate() -> String {
        if let date = createdAt {
            return format(date: date, format: "dd MMM yyyy")
        }
        return ""
    }
    
    private func makeURL(for title: String) -> URL {
        let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let url = path.appending(path: title)
        return url
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
        let date = Date.now
        let formattedTime = format(date: date, format: "yyyy-MMM-dd_HH.mm.ss")
        
        title = "New Recording \(count)"
        let fileName = "Recording_\(formattedTime).m4a"
        fileURL = makeURL(for: fileName)
        currentTime = 0
        createdAt = Date.now
        
        do {
            try audioManager.startRecording(fileURL: fileURL!)
            
            isRecording = true
            hasStartedRecording = true
            showSheet = true
            
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
        showSheet = false
        
        stopTimer()
        audioManager.stopRecording()
        saveRecording()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.title = nil
            self.fileURL = nil
            self.currentTime = 0
            self.createdAt = nil
        }
    }
    
    func saveRecording() {
        audioRepository.addRecording(
            title: title!,
            fileName: fileURL!.lastPathComponent,
            duration: currentTime,
            createdAt: createdAt!
        )
    }
    
    func deleteRecording(from recordings: [AudioModel]) {
        audioRepository.deleteRecording(for: recordings)
        expandedRecording =  nil
    }
}

// MARK: - Playback

extension RecordingViewModel {
    
    func setupPlayback(for recording: AudioModel) {
        if isPlaying {
            stopAudio()
        }
        
        let fileName = recording.fileName
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        fileURL = url.appending(path: fileName)
        
        do {
            try audioManager.setupPlayback(fileURL: fileURL!)
            
            audioManager.onPlaybackFinished = { [weak self] flag in
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
}


/*
 
 func deleteRecording(from recordings: [AudioModel]) {
     let delete = recordings.filter { selectedRecordings.contains($0.id) }
     audioRepository.deleteRecording(for: ids)
     expandedRecording =  nil
 }
 
 */
