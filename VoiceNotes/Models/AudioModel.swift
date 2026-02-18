//
//  AudioModel.swift
//  VoiceNotes
//
//  Created by Ziqa on 14/02/26.
//

import Foundation
import SwiftData

@Model
final class AudioModel {
    var title: String
    var fileName: String
    var duration: Double
    var createdAt: Date
    var isDeleted: Bool = false
    var deletedAt: Date? = nil
    var Folder: FolderModel?
    
    init(title: String, fileName: String, duration: Double, createdAt: Date) {
        self.title = title
        self.fileName = fileName
        self.duration = duration
        self.createdAt = createdAt
    }
}

extension AudioModel {
    
    static var sample = {
        return AudioModel(title: "New Recording 12", fileName: "New Recording 12", duration: 120, createdAt: Date.now)
    }()
    
}
