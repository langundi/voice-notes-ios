//
//  TranscriptionModel.swift
//  VoiceNotes
//
//  Created by Ziqa on 12/03/26.
//

import Foundation

struct TranscriptionModel {
    var finalizedText: String = ""
    var currentText: String = ""
    var isRecording: Bool = false
    
    var displayText: String {
        return finalizedText + currentText
    }
}
