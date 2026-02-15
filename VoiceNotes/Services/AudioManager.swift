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
    
    let settings: [String : Any] = [
        AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
        AVSampleRateKey: 44100.0,
        AVNumberOfChannelsKey: 1,
        AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
    ]
    
    func requestAudioPermission() async {
        await AVAudioApplication.requestRecordPermission()
    }
    
    private func microphonePermission() -> Bool {
        return AVAudioApplication.shared.recordPermission == .granted
    }
    
    func setupSession() throws {
        try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetoothHFP, .allowBluetoothA2DP])
        try session.setActive(true)
    }
    
    // MARK: - Recorder
    
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
    
    // MARK: - Playback
    
    func setupPlayback(fileURL: URL) throws {
        player = nil
        player = try AVAudioPlayer(contentsOf: fileURL)
        player?.delegate = self
    }
    
    func startPlayback() throws {
        player?.prepareToPlay()
        player?.play()
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
    
}

extension AudioManager: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        onRecordingFinished?(flag)
    }
}

extension AudioManager: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        onPlaybackFinished?(flag)
    }
}
