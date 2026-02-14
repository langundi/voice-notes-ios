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
    
    init(audioRepository: AudioRepository) {
        self.audioRepository = audioRepository
    }
    
    var isEditing: Bool = false
    var showAlert: Bool = false
    var newFolderTitle: String = ""
    
    func createNewFolder() {
        guard !newFolderTitle.trimmingCharacters(in: .whitespaces).isEmpty else {
            return
        }
        
        audioRepository.addNewFolder(title: newFolderTitle)
        
        newFolderTitle = ""
        showAlert = false
    }
    
    func deleteFolder(folder: FolderModel) {
        audioRepository.deleteFolder(folder: folder)
    }
    
    func resetAlert() {
        newFolderTitle = ""
        showAlert = false
    }
    
}
