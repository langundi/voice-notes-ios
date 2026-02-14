//
//  FolderModel.swift
//  VoiceNotes
//
//  Created by Ziqa on 14/02/26.
//

import Foundation
import SwiftData

@Model
final class FolderModel {
    var title: String
    
    @Relationship(deleteRule: .nullify, inverse: \AudioModel.Folder)
    var Audios: [AudioModel] = []
    
    init(title: String) {
        self.title = title
    }
}
