//
//  FolderEnum.swift
//  VoiceNotes
//
//  Created by Ziqa on 19/02/26.
//

import Foundation

enum FolderEnum {
    case all
    case favorites
    case custom(String)
    case trash
    
    var title: String {
        switch self {
        case .all:
            return "All Recordings"
        case .favorites:
            return "Favorites"
        case .custom(let name):
            return name
        case .trash:
            return "Recently Deleted"
        }
    }
}
