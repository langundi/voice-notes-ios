//
//  ItemRowView.swift
//  AudioRecorder
//
//  Created by Ziqa on 09/09/25.
//

import SwiftUI
import SwiftData

struct RecordingRowView: View {
    
    @Environment(RecordingViewModel.self) private var vm
    @Environment(\.colorScheme) private var colorScheme
    
    // UI Properties
    @State private var isSelected: Bool = false
    @State private var textField: String = ""
    @State private var textSelection: TextSelection?
    @FocusState private var isFocused: Bool
    @ScaledMetric private var buttonWidth: CGFloat = 44
    
    // Passed Values
    var recording: AudioModel
    var isExpanded: Bool
    
    // Computed Properties
    private var isVisuallyExpanded: Bool {
        isExpanded && !vm.isEditing
    }
    
    private var isFavorite: Bool {
        recording.isFavorite
    }
    
    private var disableButtons: Bool {
        isFocused
    }
    
    var body: some View {
        @Bindable var vm = vm
        VStack(spacing: 8) {
            Divider()
            
            HStack(alignment: .center, spacing: 8) {
                if vm.isEditing {
                    Button {
                        vm.toggleSelection(for: recording.id)
                    } label: {
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .font(.title2)
                            .foregroundStyle(isSelected ? .blue : Color.secondary)
                            .contentTransition(.symbolEffect(.replace))
                    }
                    .transition(.move(edge: .leading).combined(with: .opacity))
                    .animation(.snappy(duration: 0.2), value: isSelected)
                }
                
                TitleAndDateView()
                
                Spacer()
                
                if isVisuallyExpanded {
                    Menu {
                        ShareLink(item: getURL(for: recording.fileName)) {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                        
                        Divider()
                        
                        Button("Rename", systemImage: "pencil") {
                            isFocused = true
                            vm.hideRecordButton = true
                        }
                        
                        Button("Edit Recording", systemImage: "waveform") { }
                        
                        Divider()
                        
                        Button("Options", systemImage: "slider.horizontal.3") {
                            vm.showOptionsSheet = true
                        }
                        
                        Divider()
                        
                        Button(isFavorite ? "Unfavorite" : "Favorite", systemImage: isFavorite ? "heart.fill" : "heart") {
                            vm.favoriteRecording(recording: recording)
                        }
                        .contentTransition(.symbolEffect)
                        
                        Button("Duplicate", systemImage: "plus.square.on.square") {
                            vm.duplicateRecording(recording: recording)
                        }
                        
                        Button("Move", systemImage: "folder") {
                            vm.showSelectFolderSheet = true
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.title2)
                            .padding(.vertical)
                            .padding(.leading)
                    }
                } else {
                    Text(formatTime(time: recording.duration))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .vSpacing(.bottom)
                        .transition(.blurReplace)
                }
            }
            
            if isVisuallyExpanded {
                PlaybackControlView()
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
        .animation(.snappy(duration: K.animDuration), value: isVisuallyExpanded)
        .animation(.smooth(duration: K.animDuration), value: vm.isPlaying)
        .animation(.snappy(duration: K.animDuration), value: isSelected)
        .animation(.snappy(duration: K.animDuration), value: vm.currentTime)
        .onChange(of: vm.selectedRecordings) { oldValue, newValue in
            let currentlyInSet = newValue.contains(recording.id)
            if isSelected != currentlyInSet {
                isSelected = currentlyInSet
            }
        }
        .task {
            textField = recording.title
        }
    }
    
    @ViewBuilder
    private func TitleAndDateView() -> some View {
        VStack(alignment: .leading, spacing: 4) {
            TextField("", text: $textField, selection: $textSelection)
                .fontWeight(.semibold)
                .lineLimit(1)
                .truncationMode(.tail)
                .focused($isFocused)
                .disabled(!isExpanded || vm.isEditing)
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
                        vm.renameTitle(for: recording, newTitle: textField)
                    }
                    vm.isEditing = false
                    vm.hideRecordButton = false
                }
            
            HStack(alignment: .center) {
                Text(formatDate(date: recording.createdAt, format: "HH.mm"))
                    .font(.footnote)
                    .fontWeight(.medium)
                
                Image(systemName: "quote.bubble")
            }
            .foregroundStyle(.secondary)
        }
    }
    
    @ViewBuilder
    private func PlaybackControlView() -> some View {
        VStack(alignment: .center, spacing: 8) {
            @Bindable var vm = vm
            
            let totalDuration = recording.duration
            let config: LineScrubber.Config = .init(activeTint: colorScheme == .dark ? .white : .black)
            
            Group {
                if !vm.isRecording {
                    LineScrubber(
                        config: config,
                        current: $vm.currentTime,
                        total: totalDuration,
                        onEditingChanged: { editing in
                            if editing {
                                vm.startScrubbing()
                            } else {
                                vm.endScrubbing()
                            }
                        },
                        onScrub: { newTime in
                            if vm.isScrubbing {
                                vm.updateScrubbingPosition(to: newTime)
                            }
                        }
                    )
                    .scaleEffect(y: vm.isScrubbing ? 2 : 1, anchor: .center)
                    .animation(.bouncy, value: vm.isScrubbing)
                } else {
                    Capsule()
                        .fill(config.inActiveTint)
                        .frame(height: config.trackHeight)
                }
            }
            .padding(.top, 24)
            .allowsHitTesting(!isFocused)
            
            /// Timestamp and Duration
            HStack {
                Text(formatTime(time: vm.currentTime))
                    .contentTransition(.numericText())
                    .animation(.snappy, value: vm.currentTime)
                
                Spacer()
                
                Text("-" + formatTime(time: vm.countdown))
                    .contentTransition(.numericText())
                    .animation(.snappy, value: vm.countdown)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .monospacedDigit()
            
            /// Control Buttons
            HStack(alignment: .center, spacing: 36) {
                Button {
                    // Open sheet
                } label: {
                    Image(systemName: "waveform")
                        .fontWeight(.light)
                        .foregroundStyle(.blue)
                }
                
                Spacer()
                
                HStack(spacing: 24) {
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
                            .frame(width: buttonWidth)
                    }
                    
                    Button {
                        vm.forward15Seconds()
                    } label: {
                        Image(systemName: "15.arrow.trianglehead.clockwise")
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                Spacer()
                
                Button {
                    withAnimation(.snappy(duration: 0.2)) {
                        vm.deleteRecording(from: [recording])
                    }
                } label: {
                    Image(systemName: "trash")
                        .fontWeight(.light)
                        .foregroundStyle(.blue)
                }
            }
            .font(.title2)
            .fontWeight(.medium)
            .foregroundStyle(.primary)
            .padding(.top, 24)
            .padding(.bottom, 8)
            .allowsHitTesting(!isFocused)
        }
        .transition(.move(edge: .top).combined(with: .blurReplace))
    }
}

#Preview {
    @Previewable @State var item = RowModel(id: AudioModel.sample.id, recording: AudioModel.sample)
    @Previewable @State var properties = SelectionProperties.init()
    let vm = DIContainer.shared.makeRecordingViewModel()
    
    ScrollView {
        RecordingRowView(recording: AudioModel.sample, isExpanded: true)
        RecordingRowView(recording: AudioModel.sample, isExpanded: false)
        RecordingRowView(recording: AudioModel.sample, isExpanded: false)
        RecordingRowView(recording: AudioModel.sample, isExpanded: false)
    }
    .modelContainer(DIContainer.shared.makePreviewContainer())
    .environment(vm)
    
}
