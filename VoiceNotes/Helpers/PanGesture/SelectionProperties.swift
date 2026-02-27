//
//  SelectionProperties.swift
//  VoiceNotes
//
//  Created by Ziqa on 26/02/26.
//

import Foundation

/// Drag Selection Properties
struct SelectionProperties {
    var start: Int?
    var end: Int?
    /// This property holds the actual selected indices
    var selectedIndices: [Int] = []
    var previousIndices: [Int] = []
    var toBeDeletedIndices: [Int] = []
    var isDeleteDrag: Bool = false
}
