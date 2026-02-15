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
    
    init(audioRepository: AudioRepository) {
        self.audioRepository = audioRepository
    }
    
    // UI Attributes
    var isRecording: Bool = false
    var hasStartedRecording: Bool = false
    var showSheet: Bool = false
    var isEditing: Bool = false
    
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
    }
    
    func stopRecording() {
        isRecording = false
        hasStartedRecording = false
        showSheet = false
    }
    
    func resumeRecording() {
        isRecording = true
    }
    
    func pauseRecording() {
        isRecording = false
    }
    
}
