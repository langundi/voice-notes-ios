//
//  AudioManager.swift
//  VoiceNotes
//
//  Created by Ziqa on 15/02/26.
//

import Foundation
import AVFoundation

final class AudioManager: NSObject {
    
    private let session = AVAudioSession.sharedInstance()
    private var recorder: AVAudioRecorder?
    private var player: AVAudioPlayer?
    
    // Callbacks
    var onRecordingFinished: ((Bool) -> Void)?
    var onPlaybackFinished: ((Bool) -> Void)?
    
    var currentPlaybackTime: TimeInterval {
        player?.currentTime ?? 0
    }
    
    var currentRecordingTime: TimeInterval {
        recorder?.currentTime ?? 0
    }
    
    let settings: [String : Any] = [
        AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
        AVSampleRateKey: 44100.0,
        AVNumberOfChannelsKey: 1,
        AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
    ]
    
    func requestAudioPermission() async {
        await AVAudioApplication.requestRecordPermission()
    }
    
    func requestMircophonePermission() async -> MicrophoneAccessEnum {
        let granted = await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
        
        return granted ? .granted : .denied
    }
    
    private func microphonePermission() -> Bool {
        return AVAudioApplication.shared.recordPermission == .granted
    }
    
    func checkMicrophonePermission() -> MicrophoneAccessEnum {
        switch AVAudioApplication.shared.recordPermission {
        case .undetermined:
            return .undetermined
        case .denied:
            return .denied
        case .granted:
            return .granted
        @unknown default:
            fatalError("Unknown status")
        }
    }
    
    func setupSession() throws {
        guard microphonePermission() else {
            throw AudioManagerError.microphonePermissionDenied
        }
        
        try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetoothHFP, .allowBluetoothA2DP])
        try session.setActive(true)
    }
    
    func getCurrentTime() -> TimeInterval {
        return player!.currentTime
    }
}

// MARK: - Audio Recorder

extension AudioManager: AVAudioRecorderDelegate {
    
    func startRecording(fileURL: URL) throws {
        guard microphonePermission() else {
            throw AudioManagerError.microphonePermissionDenied
        }
        
        recorder = try AVAudioRecorder(url: fileURL, settings: settings)
        recorder?.delegate = self
        recorder?.isMeteringEnabled = true
        recorder?.prepareToRecord()
        recorder?.record()
    }
    
    func pauseRecording() {
        recorder?.pause()
    }
    
    func resumeRecording() {
        recorder?.record()
    }
    
    func stopRecording() {
        recorder?.stop()
        recorder?.isMeteringEnabled = false
        recorder = nil
    }
    
    func cancelRecording() {
        recorder?.stop()
        recorder?.isMeteringEnabled = false
        recorder?.deleteRecording()
        recorder = nil
    }
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        onRecordingFinished?(flag)
    }
}

// MARK: - Audio Player

extension AudioManager: AVAudioPlayerDelegate {
    
    func setupPlayback(fileURL: URL) throws {
        player = nil
        player = try AVAudioPlayer(contentsOf: fileURL)
        player?.delegate = self
    }
    
    func startPlayback() throws {
        player?.prepareToPlay()
        player?.play()
    }
    
    func play(at time: TimeInterval) {
        player?.play(atTime: time)
    }
    
    func seek(at time: TimeInterval) throws { 
        if let currentTime = player?.currentTime {
            let newTime = currentTime + time
            player?.currentTime = newTime
        }
    }
    
    func pausePlayback() {
        player?.pause()
    }
    
    func resumePlayback() {
        player?.play()
    }
    
    func stopPlayback() {
        player?.stop()
        player = nil
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        onPlaybackFinished?(flag)
    }
}
