//
//  AudioManagerError.swift
//  VoiceNotes
//
//  Created by Ziqa on 15/02/26.
//

import Foundation

enum AudioManagerError: LocalizedError {
    case sessionSetupFailed(Error)
    case microphonePermissionDenied
    case recorderInitFailed(Error)
    case playerInitFailed(Error)
    case noActiveRecording
    case noActivePlayback
    case audioEngineFailed(Error)
    case mergeFailure
    
    var errorDescription: String? {
        switch self {
        case .sessionSetupFailed(let e):   return "Audio session setup failed: \(e.localizedDescription)"
        case .microphonePermissionDenied:  return "Microphone permission was denied."
        case .recorderInitFailed(let e):   return "Failed to initialize recorder: \(e.localizedDescription)"
        case .playerInitFailed(let e):     return "Failed to initialize player: \(e.localizedDescription)"
        case .noActiveRecording:           return "No active recording in progress."
        case .noActivePlayback:            return "No active playback in progress."
        case .audioEngineFailed(let e): return "Failed to start audio engine: \(e.localizedDescription)"
        case .mergeFailure: return "Failed to merge audio URLs"
        }
    }
}
