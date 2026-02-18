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
    
    private var title: String?
    private var fileURL: URL?
    private var createdAt: Date?
    private var timer: Timer?
    
    // UI Attributes
    var hasStartedRecording: Bool = false
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
    var duration: TimeInterval = 0
    var expandedRecording: AudioModel.ID? = nil
    var selectedRecordings: Set<AudioModel.ID> = []
    
    func resetUI() {
        isRecording = false
        hasStartedRecording = false
        showSheet = false
        isEditing = false
    }
    
    func toggleSelection(for id: AudioModel.ID) {
        if selectedRecordings.contains(id) {
            selectedRecordings.remove(id)
        } else {
            selectedRecordings.insert(id)
        }
    }
    
    // MARK: - Recording
    
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
        isRecording = true
        hasStartedRecording = true
        showSheet = true
        
        let now = Date.now
        let formattedDate = format(date: now, format: "dd MMM yyyy")
        let count = audioRepository.getAudioCount()
        
        title = "Recording \(count) - \(formattedDate)"
        fileURL = makeURL(for: title!)
        duration = 0
        createdAt = now
        
        do {
            try audioManager.startRecording(fileURL: fileURL!)
            startTimer()
        } catch {
            print("error start recording: \(error.localizedDescription)")
        }
    }
    
    func stopRecording() {
        isRecording = false
        hasStartedRecording = false
        showSheet = false
        
        stopTimer()
        
        audioManager.stopRecording()
        
        saveRecording()
        
        title = nil
        fileURL = nil
        duration = 0
        createdAt = nil
    }
    
    func resumeRecording() {
        isRecording = true
    }
    
    func pauseRecording() {
        isRecording = false
    }
    
    // MARK: - Data
    
    func saveRecording() {
        if let url = fileURL, let title = title, let date = createdAt {
            audioRepository.addRecording(title: title, fileURL: url, duration: duration, createdAt: date)
        }
    }
    
    func deleteRecording(_ audio: AudioModel) {
        audioRepository.deleteRecording(audio: audio)
        expandedRecording =  nil
    }
    
    // MARK: - Helper
    
    private func makeURL(for title: String) -> URL {
        let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let url = path.appending(path: title)
        return url
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.duration += 1
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
}
