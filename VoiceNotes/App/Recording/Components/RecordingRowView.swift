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
    
    // UI Properties
    @State private var isSelected: Bool = false
    @State private var textField: String = ""
    @State private var selection: TextSelection?
    @FocusState private var isFocused: Bool
    @ScaledMetric private var buttonWidth: CGFloat = 44
    
    // Passed Values
    @Binding var rowItem: RowModel
    let recording: AudioModel
    var isExpanded: Bool
    @Binding var properties: SelectionProperties
    @Binding var hideRecordButton: Bool
    
    // Computed Properties
    private var isVisuallyExpanded: Bool {
        isExpanded && !vm.isEditing
    }
    
    var body: some View {
        @Bindable var vm = vm
        
        if let index = vm.rowItems.firstIndex(where: { $0.id == recording.id }) {
            VStack(spacing: 6) {
                Divider()
                
                HStack(alignment: .center, spacing: 8) {
                    if vm.isEditing {
                        Button {
                            vm.toggleSelection(for: recording.id)
                            //                        vm.toggleRowSelection(for: recording.id)
                        } label: {
                            HStack {
                                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                    .font(.title2)
                                    .foregroundStyle(isSelected ? .blue : Color.secondary)
                                    .contentTransition(.symbolEffect(.replace))
                            }
                            
                            HStack {
                                let isSelected = properties.selectedIndices.contains(index) && !properties.toBeDeletedIndices.contains(index)
                                
                                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                    .font(.title2)
                                    .foregroundStyle(isSelected ? .blue : Color.secondary)
                                    .contentTransition(.symbolEffect(.replace))
                            }
                            
                        }
                        .overlay(alignment: .center) {
                            if vm.isEditing {
                                Rectangle()
                                    .padding()
                                    .foregroundStyle(.green)
                                    .opacity(0.5)
                                    .contentShape(.rect)
                                    .onTapGesture {
                                        if properties.selectedIndices.contains(index) {
                                            properties.selectedIndices.removeAll { $0 == index }
                                        } else {
                                            properties.selectedIndices.append(index)
                                        }
                                        
                                        properties.previousIndices = properties.selectedIndices
                                    }
                            }
                        }
                        .transition(.move(edge: .leading).combined(with: .opacity))
                        .animation(.snappy(duration: 0.2), value: isSelected)
                    }
                    
                    titleAndDateView()
                    
                    Spacer()
                    
                    if isVisuallyExpanded {
                        Menu {
                            ShareLink(item: getURL(for: recording.fileName)) {
                                Label("Share", systemImage: "square.and.arrow.up")
                            }
                            Divider()
                            Button("Rename", systemImage: "pencil") {
                                isFocused = true
                                hideRecordButton = true
                            }
                            Button("Edit Recording", systemImage: "waveform") { }
                            
                            Divider()
                            
                            Button("Options", systemImage: "slider.horizontal.3") {
                                vm.showOptionsSheet = true
                            }
                            
                            Divider()
                            
                            Button(recording.isFavorite ? "Unfavorite" : "Favorite",
                                   systemImage: recording.isFavorite ? "heart.fill" : "heart") {
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
                    playbackControlView()
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 6)
            .animation(.snappy(duration: 0.3), value: isVisuallyExpanded)
            .onGeometryChange(for: CGRect.self) {
                $0.frame(in: .global)
            } action: { newValue in
                rowItem.location = newValue
            }
            .onChange(of: vm.selectedRecordings) { oldValue, newValue in
                let currentlyInSet = newValue.contains(recording.id)
                if isSelected != currentlyInSet {
                    isSelected = currentlyInSet
                }
            }
            .onAppear {
                isSelected = vm.selectedRecordings.contains(recording.id)
                //            isSelected = vm.selectedRow.contains(recording.id)
                textField = recording.title
            }
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
                .disabled(vm.isEditing)
                .onChange(of: isFocused) { oldValue, newValue in
                    if isFocused {
                        selection = .init(range: textField.startIndex..<textField.endIndex)
                    }
                }
                .onSubmit {
                    if textField.isEmpty {
                        textField = recording.title
                    } else {
                        vm.renameTitle(for: recording, newTitle: textField)
                    }
                    vm.isEditing = false
                    hideRecordButton = false
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
    private func playbackControlView() -> some View {
        VStack(alignment: .center, spacing: 4) {
            RoundedRectangle(cornerRadius: 50)
                .fill(.quaternary)
                .frame(maxWidth: .infinity, maxHeight: 6)
                .padding(.top, 24)
            
            HStack {
                Text(formatTime(time: vm.currentTime))
                Spacer()
                Text(formatTime(time: recording.duration))
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
            .padding(.bottom, 4)
        }
        .transition(.move(edge: .top).combined(with: .blurReplace))
    }
    
}

#Preview {
    @Previewable @State var item = RowModel(id: AudioModel.sample.id, recording: AudioModel.sample)
    @Previewable @State var properties = SelectionProperties.init()
    let vm = DIContainer.shared.makeRecordingViewModel()
    
    ScrollView {
        RecordingRowView(rowItem: $item, recording: AudioModel.sample, isExpanded: true, properties: $properties, hideRecordButton: .constant(true))
        RecordingRowView(rowItem: $item, recording: AudioModel.sample, isExpanded: false, properties: $properties, hideRecordButton: .constant(true))
    }
    .modelContainer(DIContainer.shared.makePreviewContainer())
    .environment(vm)
    
}
