//
//  AudioManagerError.swift
//  VoiceNotes
//
//  Created by Ziqa on 15/02/26.
//

import Foundation

enum AudioManagerError: LocalizedError {
    case microphonePermissionDenied
    case audioEngineFailed(Error)
    case mergeFailure
    
    var errorDescription: String? {
        switch self {
        case .microphonePermissionDenied: 
            return "Microphone permission was denied."
        case .audioEngineFailed(let e): 
            return "Failed to start audio engine: \(e.localizedDescription)"
        case .mergeFailure: 
            return "Failed to merge audio URLs"
        }
    }
}
