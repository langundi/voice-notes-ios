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
    @State private var textField: String = ""
    @State private var textSelection: TextSelection?
    @FocusState private var isFocused: Bool
    @ScaledMetric private var buttonWidth: CGFloat = 44
    
    // Passed Values
    @Binding var rowItem: RowModel
    var index: Int
    var isExpanded: Bool
    @Binding var properties: SelectionProperties
    
    // Computed Properties
    private var isVisuallyExpanded: Bool {
        isExpanded && !vm.isEditing
    }
    
    private var isSelected: Bool {
        properties.selectedIndices.contains(index) && !properties.toBeDeletedIndices.contains(index)
    }
    
    private var isFavorite: Bool {
        rowItem.recording.isFavorite
    }
    
    var body: some View {
        @Bindable var vm = vm
            VStack(spacing: 6) {
                Divider()
                
                HStack(alignment: .center, spacing: 8) {
                    if vm.isEditing {
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .font(.title2)
                            .foregroundStyle(isSelected ? .blue : Color.secondary)
                            .contentTransition(.symbolEffect(.replace))
                            .transition(.move(edge: .leading).combined(with: .opacity))
                    }
                    
                    TitleAndDateView()
                    
                    Spacer()
                    
                    if isVisuallyExpanded {
                        Menu {
                            ShareLink(item: getURL(for: rowItem.recording.fileName)) {
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
                                vm.favoriteRecording(recording: rowItem.recording)
                            }
                            .contentTransition(.symbolEffect)
                            
                            Button("Duplicate", systemImage: "plus.square.on.square") {
                                vm.duplicateRecording(recording: rowItem.recording)
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
                        Text(formatTime(time: rowItem.recording.duration))
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
            .padding(.vertical, 6)
            .animation(.snappy(duration: K.animDuration), value: isVisuallyExpanded)
            .animation(.smooth(duration: K.animDuration), value: vm.isPlaying)
            .animation(.snappy(duration: K.animDuration), value: isSelected)
            .onGeometryChange(for: CGRect.self) {
                $0.frame(in: .global)
            } action: { newValue in
                rowItem.location = newValue
            }
            .task {
                textField = rowItem.recording.title
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
                        textSelection = .init(range: textField.startIndex..<textField.endIndex)
                        vm.hideRecordButton = true
                    }
                }
                .onSubmit {
                    // Reset name when text field left empty
                    if textField.isEmpty {
                        textField = rowItem.recording.title
                    } else {
                        vm.renameTitle(for: rowItem.recording, newTitle: textField)
                    }
                    vm.isEditing = false
                    vm.hideRecordButton = false
                }
            
            HStack(alignment: .center) {
                Text(formatDate(date: rowItem.recording.createdAt, format: "HH.mm"))
                    .font(.footnote)
                    .fontWeight(.medium)
                
                Image(systemName: "quote.bubble")
            }
            .foregroundStyle(.secondary)
        }
    }
    
    @ViewBuilder
    private func PlaybackControlView() -> some View {
        VStack(alignment: .center, spacing: 4) {
            RoundedRectangle(cornerRadius: 50)
                .fill(.quaternary)
                .frame(maxWidth: .infinity, maxHeight: 6)
                .padding(.top, 24)
            
            HStack {
                Text(formatTime(time: vm.currentTime))
                
                Spacer()
                
                Text(formatTime(time: rowItem.recording.duration))
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
                        vm.deleteRecording(from: [rowItem.recording])
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
        RecordingRowView(rowItem: $item, index: 0, isExpanded: true, properties: $properties)
        RecordingRowView(rowItem: $item, index: 1, isExpanded: false, properties: $properties)
    }
    .modelContainer(DIContainer.shared.makePreviewContainer())
    .environment(vm)
    
}
