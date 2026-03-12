//
//  TranscriptionManager.swift
//  VoiceNotes
//
//  Created by Ziqa on 12/03/26.
//

import Foundation
import Speech

@available(iOS 26.0, *)
class TranscriptionManager {
    
    private var inputBuilder: AsyncStream<AnalyzerInput>.Continuation?
    private var transcriber: SpeechTranscriber?
    private var analyzer: SpeechAnalyzer?
    private var recognizerTask: Task<(), Error>?
    private var analyzerFormat: AVAudioFormat?
    private var converter = BufferConverter()
    
    
    func requestSpeechPermission() async -> Bool {
        let status = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
        return status == .authorized
    }
    
    
    func startTranscription(onResult: @escaping (String, Bool) -> Void) async throws {
        transcriber = SpeechTranscriber(
            locale: Locale(identifier: "en_US"),
            transcriptionOptions: [],
            reportingOptions: [.volatileResults],
            attributeOptions: [.audioTimeRange]
        )
        analyzer = SpeechAnalyzer(modules: [transcriber!])
        analyzerFormat = await SpeechAnalyzer.bestAvailableAudioFormat(compatibleWith: [transcriber!])
        
        let (inputSequence, inputBuilder) = AsyncStream<AnalyzerInput>.makeStream()
        self.inputBuilder = inputBuilder
        
        recognizerTask = Task {
            for try await result in transcriber!.results {
                let text = String(result.text.characters)
                onResult(text, result.isFinal)
            }
        }
        
        try await analyzer?.start(inputSequence: inputSequence)
    }
    
    
    func processAudioBuffer(_ buffer: AVAudioPCMBuffer) throws {
        guard let inputBuilder, let analyzerFormat else { return }
        let converted = try converter.convertBuffer(buffer, to: analyzerFormat)
        inputBuilder.yield(AnalyzerInput(buffer: converted))
    }
    
    
    func stopTranscription() async {
        inputBuilder?.finish()
        try? await analyzer?.finalizeAndFinishThroughEndOfInput()
        recognizerTask?.cancel()
        recognizerTask = nil
    }
}
