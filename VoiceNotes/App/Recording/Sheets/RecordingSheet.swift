//
//  ExpandedRecordingSheet.swift
//  VoiceNotes
//
//  Created by Ziqa on 15/02/26.
//

import SwiftUI

struct RecordingSheet: View {
    
    @Environment(RecordingViewModel.self) private var vm
    
    @ScaledMetric private var buttonWidth: CGFloat = 44
    
    @State private var showTranscription: Bool = false
    @State private var textField: String = ""
    @State private var textSelection: TextSelection?
    @FocusState private var isFocused: Bool
    
    let folderTitle: String
    var recording: AudioModel?
    
    var body: some View {
        @Bindable var vm = vm
        
        NavigationStack {
            VStack(spacing: 24) {
                SheetHeader()
                
                if showTranscription {
                    TranscriptionView()
                        .frame(maxHeight: .infinity, alignment: .top)
                        .padding(.bottom, 24)
                } else {
                    if recording == nil {
                        WaveformView(samples: vm.samples, isRecording: vm.isRecording, duration: vm.recordingTime)
                            .frame(maxHeight: .infinity)
                            .padding(.bottom, 24)
                    } else {
                        if let recording = recording {
                            WaveformView(samples: recording.samples + vm.samples, isRecording: vm.isRecording, duration: recording.duration)
                                .frame(maxHeight: .infinity)
                                .padding(.bottom, 24)
                        }
                    }
                }
                
                SheetControls()
            }
            .toolbar {
                if recording != nil {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Rename", systemImage: "pencil") {
                            isFocused = true
                        }
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", systemImage: "checkmark") {
                        if vm.hasStartedRecording {
                            Task {
                                await vm.stopAndSave(folderTitle: folderTitle)
                            }
                        } else {
                            vm.dismissRecordingSheet()
                        }
                    }
                }
            }
            .background(.gray.opacity(0.05))
            .animation(.smooth(duration: 0.2), value: showTranscription)
        }
    }
    
    @ViewBuilder
    private func SheetHeader() -> some View {
        VStack(alignment: .center, spacing: 2) {
            if recording == nil {
                Text((vm.title ?? recording?.title) ?? "-")
                    .font(.title2)
                    .fontWeight(.bold)
            } else {
                if let recording = recording {
                    TextField("", text: $textField, selection: $textSelection)
                        .multilineTextAlignment(.center)
                        .font(.title2)
                        .fontWeight(.bold)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .focused($isFocused)
                        .onChange(of: isFocused) { oldValue, newValue in
                            if isFocused {
                                vm.stopAudio()
                                vm.hideRecordButton = true
                                textSelection = .init(range: textField.startIndex..<textField.endIndex)
                            }
                        }
                        .onSubmit {
                            // Reset name when text field left empty
                            if textField.isEmpty {
                                textField = recording.title
                            } else {
                                print("rename to : \(textField)")
                                vm.renameTitle(for: recording, newTitle: textField)
                                vm.setupPlayback(for: recording)
                            }
                            vm.isEditing = false
                            vm.hideRecordButton = false
                        }
                }
            }
            
            HStack(alignment: .center, spacing: 8) {
                Text("\(formatDate(date: (vm.createdAt ?? recording?.createdAt) ?? Date.now))")
                    .foregroundStyle(.secondary)
                    .fontWeight(.semibold)
                
                Text("\(formatTime(time: max(0, vm.currentTime)))")
                    .foregroundStyle(.gray)
                    .monospacedDigit()
            }
            .frame(maxWidth: .infinity)
            .task {
                if let recording = recording {
                    textField = recording.title
                }
            }
        }
    }
    
    @ViewBuilder
    private func TranscriptionView() -> some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical) {
                if recording == nil {
                    if !vm.transcriptionModel.displayText.isEmpty {
                        Text(vm.transcriptionModel.displayText)
                            .font(.title3)
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                            .padding(.horizontal, 36)
                            .id("transcriptionText")
                    } else {
                        EmptyView()
                    }
                } else {
                    if let recording = recording {
                        Text(recording.transcript)
                            .font(.title3)
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                            .padding(.horizontal, 36)
                        
                        if !vm.transcriptionModel.displayText.isEmpty {
                            Text(vm.transcriptionModel.displayText)
                                .font(.title3)
                                .fontWeight(.bold)
                                .frame(maxWidth: .infinity, alignment: .topLeading)
                                .padding(.horizontal, 36)
                                .id("transcriptionText")
                        } else {
                            EmptyView()
                        }
                    }
                }
            }
            .onChange(of: vm.transcriptionModel.displayText) { _, _ in
                withAnimation {
                    proxy.scrollTo("transcriptionText", anchor: .bottom)
                }
            }
        }
    }
    
    @ViewBuilder
    private func SheetControls() -> some View {
        VStack(spacing: 36) {
            Text("\(formatTimer(time: max(0,vm.currentTime)))")
                .font(.largeTitle)
                .fontWeight(.bold)
                .monospacedDigit()
            
            HStack(spacing: 32) {
                Button {
                    vm.rewind15Seconds()
                } label: {
                    Image(systemName: "15.arrow.trianglehead.counterclockwise")
                }
                
                Button {
                    vm.togglePlayback()
                } label: {
                    Image(systemName: vm.isPlaying ? "pause.fill" : "play.fill")
                        .font(.largeTitle)
                        .contentTransition(.symbolEffect(.replace))
                        .animation(.smooth(duration: K.animDuration), value: vm.isPlaying)
                        .frame(width: buttonWidth)
                }
                
                Button {
                    vm.forward15Seconds()
                } label: {
                    Image(systemName: "15.arrow.trianglehead.clockwise")
                }
            }
            .font(.title)
            .fontWeight(.medium)
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity)
            .disabled(vm.isRecording)
            
            HStack {
                Button {
                    showTranscription.toggle()
                } label: {
                    Image(systemName: "quote.bubble")
                }
                .buttonStyle(ToolBarButtonStyle())
                
                Spacer()
                
                if recording == nil {
                    Button {
                        Task {
                            await vm.toggleRecording()
                        }
                    } label: {
                        Group {
                            if vm.isRecording {
                                Image(systemName: "pause.fill")
                            } else {
                                Text("RESUME")
                            }
                        }
                        .transition(.blurReplace)
                    }
                    .buttonStyle(RecordButtonStyle(isRecording: vm.isRecording))
                    
                    Spacer()
                    
                    Button {
                        if vm.hasStartedRecording {
                            Task {
                                await vm.stopAndSave(folderTitle: folderTitle)
                            }
                        } else {
                            vm.dismissRecordingSheet()
                        }
                    } label: {
                        Group {
                            if #available(iOS 26, *) {
                                Image(systemName: "stop.fill")
                            } else {
                                Image(systemName: "stop.circle")
                                    .font(.title)
                            }
                        }
                        .foregroundStyle(.red)
                    }
                    .buttonStyle(ToolBarButtonStyle())
                }
            }
            .padding(.horizontal, 36)
        }
    }
}

#Preview {
    let vm = DIContainer.shared.makeRecordingViewModel()
    RecordingSheet(folderTitle: "All Recordings")
        .environment(vm)
}
