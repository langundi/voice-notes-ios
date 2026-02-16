//
//  HomeViewModel.swift
//  VoiceNotes
//
//  Created by Ziqa on 14/02/26.
//

import Foundation

@Observable
final class HomeViewModel {
    
    private let audioRepository: AudioRepository
    private let audioManager: AudioManager
    
    init(audioRepository: AudioRepository, audioManager: AudioManager) {
        self.audioRepository = audioRepository
        self.audioManager = audioManager
    }
    
    // UI Properties
    var isEditing: Bool = false
    var showAlert: Bool = false
    var showMicrophoneAlert: Bool = false
    var newFolderTitle: String = ""
    var microphoneAccess: MicrophoneAccessEnum = .undetermined
    
    // MARK: - Microphone access
    
    func checkMicrophonePermission() {
        let status = audioManager.checkMicrophonePermission()
        switch status {
        case .undetermined:
            microphoneAccess = status
        case .denied:
            microphoneAccess = status
        case .granted:
            microphoneAccess = status
        }
    }
    
    func requestMicrophonePermissions(onFinish: @escaping () -> Void) async {
        let status = await audioManager.requestMircophonePermission()
        microphoneAccess = status
        
        onFinish()
    }
    
    func setupAudioSession() {
        do {
            try audioManager.setupSession()
        } catch {
            print(error.localizedDescription)
        }
    }
    
    // MARK: - Folder
    
    func createNewFolder() {
        guard !newFolderTitle.trimmingCharacters(in: .whitespaces).isEmpty else {
            return
        }
        
        audioRepository.addNewFolder(title: newFolderTitle)
        
        resetAlert()
    }
    
    func deleteFolder(folder: FolderModel) {
        audioRepository.deleteFolder(folder: folder)
    }
    
    func resetAlert() {
        newFolderTitle = ""
        showAlert = false
    }
    
}
