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
    
    var isEditing: Bool = false
    var showAlert: Bool = false
    var newFolderTitle: String = ""
    
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
    
    func setupAudioSession() throws {
        try audioManager.setupSession()
    }
}
