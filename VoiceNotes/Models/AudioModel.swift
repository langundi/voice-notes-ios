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
    var fileURL: URL
    var duration: Double
    var createdAt: Date
    var isDeleted: Bool = false
    var deletedAt: Date? = nil
    var Folder: FolderModel?
    
    init(title: String, fileURL: URL, duration: Double, createdAt: Date) {
        self.title = title
        self.fileURL = fileURL
        self.duration = duration
        self.createdAt = createdAt
    }
}

extension AudioModel {
    
    static var sample = {
        let url = URL.documentsDirectory.appending(path: "New Recording 12.m4a")
        return AudioModel(title: "New Recording 12", fileURL: url, duration: 120, createdAt: Date.now)
    }()
    
}
