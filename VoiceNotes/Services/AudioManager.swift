//
//  AudioManager.swift
//  VoiceNotes
//
//  Created by Ziqa on 15/02/26.
//

import Foundation
import AVFoundation

@Observable
final class AudioManager: NSObject {
    
    private let session = AVAudioSession.sharedInstance()
    private let audioEngine = AVAudioEngine()
    
    private var audioFile: AVAudioFile?
    private var recorder: AVAudioRecorder?
    private var player: AVAudioPlayer?
    
    private let bufferSize: UInt32 = 1024
    
    // Callbacks
    var onRecordingFinished: ((Bool) -> Void)?
    var onPlaybackFinished: ((Bool) -> Void)?
    
    var currentPlaybackTime: TimeInterval {
        player?.currentTime ?? 0
    }
    
    var totalDuration: TimeInterval {
        player?.duration ?? 0
    }
    
    var currentRecordingTime: TimeInterval {
        recorder?.currentTime ?? 0
    }
    
    var samples: [Float] = []
    
    private let settings: [String : Any] = [
        AVFormatIDKey: Int(kAudioFormatLinearPCM),
        AVSampleRateKey: 48_000.0,
        AVNumberOfChannelsKey: 1,
        AVLinearPCMBitDepthKey: 32
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
    
    private func microphonePermission() -> Bool {
        return AVAudioApplication.shared.recordPermission == .granted
    }
    
}


// MARK: - Audio Player

extension AudioManager: AVAudioPlayerDelegate {
    
    func setupPlayback(fileURL: URL, rate: Float) throws {
        player = nil
        player = try AVAudioPlayer(contentsOf: fileURL)
        player?.delegate = self
        player?.enableRate = true
        player?.rate = rate
    }
    
    func startPlayback() throws {
        player?.prepareToPlay()
        player?.play()
    }
    
    func seek(to time: TimeInterval) {
        let clampedTime = max(0, (min(time, totalDuration)))
        player?.currentTime = clampedTime
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
    
    func updateRate(to newRate: Float) {
        player?.rate = newRate
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        onPlaybackFinished?(flag)
    }
}


// MARK: - Audio Engine

extension AudioManager {
    
    func startRecording(for fileURL: URL, onBuffer: @escaping (AVAudioPCMBuffer) -> Void) throws {
        audioEngine.reset()
        
        let inputNode = audioEngine.inputNode
        let format = audioEngine.inputNode.outputFormat(forBus: 0)
        
        audioFile = try! AVAudioFile(
            forWriting: fileURL,
            settings: settings,
            commonFormat: .pcmFormatFloat32,
            interleaved: false
        )
        
        inputNode.installTap(onBus: 0, bufferSize: bufferSize, format: format) { [weak self] buffer, _ in
            guard let self else { return }
            
            try? self.audioFile?.write(from: buffer)
            onBuffer(buffer)
            // Calculate samples for audio waveform
            processSamples(buffer: buffer)
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
        } catch {
            throw AudioManagerError.audioEngineFailed(error)
        }
    }
    
    func pauseRecording() {
        audioEngine.pause()
    }
    
    func resumeRecording() throws {
        do {
            try audioEngine.start()
        } catch {
            throw AudioManagerError.audioEngineFailed(error)
        }
    }
    
    func stopRecording() {
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        audioFile = nil
        audioEngine.reset()
    }
    
    /// Merge URL recordings
    func mergeSegments(_ segmentURLs: [URL], into outputURL: URL) async throws {
        let composition = AVMutableComposition()
        
        guard let compositionTrack = composition.addMutableTrack(
            withMediaType: .audio,
            preferredTrackID: kCMPersistentTrackID_Invalid
        ) else {
            throw AudioManagerError.mergeFailure
        }
        
        var insertTime = CMTime.zero
        
        for url in segmentURLs {
            let asset = AVURLAsset(url: url)
            let duration = try await asset.load(.duration)
            
            guard let assetTrack = try await asset.loadTracks(withMediaType: .audio).first else {
                continue
            }
            
            let timeRange = CMTimeRange(start: .zero, duration: duration)
            try compositionTrack.insertTimeRange(timeRange, of: assetTrack, at: insertTime)
            insertTime = CMTimeAdd(insertTime, duration)
        }
        
        guard let exportSession = AVAssetExportSession(
            asset: composition,
            presetName: AVAssetExportPresetAppleM4A
        ) else {
            throw AudioManagerError.mergeFailure
        }
        
        try await exportSession.export(to: outputURL, as: .m4a)
    }
    
    func removeSamples() {
        samples.removeAll()
    }
    
    private func processSamples(buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        let frameCount = Int(buffer.frameLength)
        
        // Calculate RMS (Root Mean Square) amplitude for smooth waveform
        var sum: Float = 0
        for i in 0..<frameCount {
            let sample = channelData[i]
            sum += sample * sample
        }
        let rms = sqrt(sum / Float(frameCount))
        
        // Normalize to 0.0 - 1.0 range
        let normalizedValue = min(rms * 10, 1.0) // Adjust multiplier for sensitivity
        
        DispatchQueue.main.async {
            self.samples.append(normalizedValue)
        }
    }
    
}


// MARK: - Audio Recorder

//extension AudioManager: AVAudioRecorderDelegate {
//
//    func startRecording(fileURL: URL) throws {
//        guard microphonePermission() else {
//            throw AudioManagerError.microphonePermissionDenied
//        }
//
//        recorder = try AVAudioRecorder(url: fileURL, settings: settings)
//        recorder?.delegate = self
//        recorder?.isMeteringEnabled = true
//        recorder?.prepareToRecord()
//        recorder?.record()
//    }
//
//    func pauseRecording() {
//        recorder?.pause()
//    }
//
//    func resumeRecording() {
//        recorder?.record()
//    }
//
//    func stopRecording() {
//        recorder?.stop()
//        recorder?.isMeteringEnabled = false
//        recorder = nil
//    }
//
//    func cancelRecording() {
//        recorder?.stop()
//        recorder?.isMeteringEnabled = false
//        recorder?.deleteRecording()
//        recorder = nil
//    }
//
//    func getCurrentTime() -> TimeInterval {
//        return player!.currentTime
//    }
//
//    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
//        onRecordingFinished?(flag)
//    }
//}
