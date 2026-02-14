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
    
    init(title: String, fileURL: URL, duration: Double) {
        self.title = title
        self.fileURL = fileURL
        self.duration = duration
        self.createdAt = .now
    }
}
