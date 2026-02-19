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
    @ScaledMetric private var buttonWidth: CGFloat = 44
    @State private var isSelected: Bool = false
    @State private var textField: String = ""
    @State private var selection: TextSelection?
    @FocusState private var isFocused: Bool
    
    let recording: AudioModel
    var isExpanded: Bool
    private var isVisuallyExpanded: Bool {
        isExpanded && !vm.isEditing
    }
    
    var body: some View {
        @Bindable var vm = vm
        
        VStack(spacing: 6) {
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

                titleAndDateView()
                
                Spacer()
                
                if isVisuallyExpanded {
                    Menu {
                        Button("Share", systemImage: "square.and.arrow.up") { }
                        Divider()
                        Button("Rename", systemImage: "pencil") {
                            isFocused = true
                        }
                        Button("Edit Recording", systemImage: "waveform") { }
                        Divider()
                        Button("Options", systemImage: "slider.horizontal.3") { }
                        Divider()
                        Button("Favorite", systemImage: "heart") { }
                        Button("Duplicate", systemImage: "plus.square.on.square") {
                            vm.duplicateRecording(recording: recording)
                        }
                        Button("Move", systemImage: "folder") { }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.title2)
                            .padding(.vertical)
                            .padding(.leading)
                    }
                } else {
                    Text(format(time: recording.duration))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .vSpacing(.bottom)
                        .transition(.blurReplace)
                }
            }
            
            if isVisuallyExpanded {
                playbackControlView()
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
        .animation(.snappy(duration: 0.3), value: isVisuallyExpanded)
        .onChange(of: vm.selectedRecordings) { oldValue, newValue in
            let currentlyInSet = newValue.contains(recording.id)
            if isSelected != currentlyInSet {
                isSelected = currentlyInSet
            }
        }
        .onAppear {
            isSelected = vm.selectedRecordings.contains(recording.id)
            textField = recording.title
        }
    }
    
    @ViewBuilder
    private func titleAndDateView() -> some View {
        VStack(alignment: .leading, spacing: 4) {
            TextField("", text: $textField, selection: $selection)
                .fontWeight(.semibold)
                .lineLimit(1)
                .truncationMode(.tail)
                .focused($isFocused)
                .disabled(!isExpanded)
                .onChange(of: isFocused) { oldValue, newValue in
                    if isFocused {
                        selection = .init(range: textField.startIndex..<textField.endIndex)
                    }
                }
                .onSubmit {
                    if textField.isEmpty {
                        textField = recording.title
                    } else {
                        vm.renameTitle(for: recording, title: textField)
                    }
                }
            
            HStack(alignment: .center) {
                Text(format(date: recording.createdAt, format: "HH.mm"))
                    .font(.footnote)
                    .fontWeight(.medium)
                
                Image(systemName: "quote.bubble")
            }
            .foregroundStyle(.secondary)
        }
    }
    
    @ViewBuilder
    private func playbackControlView() -> some View {
        VStack(alignment: .center, spacing: 4) {
            RoundedRectangle(cornerRadius: 50)
                .fill(.quaternary)
                .frame(maxWidth: .infinity, maxHeight: 6)
                .padding(.top, 24)
            
            HStack {
                Text(format(time: vm.currentTime))
                Spacer()
                Text(format(time: recording.duration))
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .monospacedDigit()
            
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
                            .animation(.smooth, value: vm.isPlaying)
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
                    vm.deleteRecording(from: [recording])
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
            .padding(.bottom, 4)
        }
        .transition(.move(edge: .top).combined(with: .blurReplace))
    }
}

#Preview {
    let vm = DIContainer.shared.makeRecordingViewModel()
    
    ScrollView {
        RecordingRowView(recording: AudioModel.sample, isExpanded: true)
        RecordingRowView(recording: AudioModel.sample, isExpanded: false)
    }
    .modelContainer(DIContainer.shared.makePreviewContainer())
    .environment(vm)
    
}
