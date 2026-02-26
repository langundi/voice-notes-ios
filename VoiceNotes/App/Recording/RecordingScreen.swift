//
//  RecordingScreen.swift
//  VoiceNotes
//
//  Created by Ziqa on 14/02/26.
//

import SwiftUI
import SwiftData

struct RecordingScreen: View {
    
    @State private var vm = DIContainer.shared.makeRecordingViewModel()
    @State private var hideRecordButton = false
    
    @Environment(\.modelContext) private var context
    @Environment(\.editMode) private var editMode
    
    @Namespace private var namespace
    
    @Query var recordings: [AudioModel]
    
    var navigationTitle: String?
    
    init(folderTitle: FolderEnum) {
        switch folderTitle {
        case .all:
            _recordings = Query(sort: \.createdAt, order: .reverse, animation: .smooth(duration: 0.2))
            navigationTitle = folderTitle.title
        case .favorites:
            let predicate = #Predicate<AudioModel> { state in
                state.isFavorite
            }
            _recordings = Query(filter: predicate, sort: \.createdAt, order: .reverse, animation: .smooth(duration: 0.2))
            navigationTitle = folderTitle.title
        case .custom(let name):
            let predicate = #Predicate<AudioModel> { audio in
                audio.Folder?.title == name
            }
            _recordings = Query(filter: predicate, sort: \.createdAt, order: .reverse, animation: .smooth(duration: 0.2))
            navigationTitle = name
        }
    }
    
    var body: some View {
        GeometryReader {
            let size = $0.size
            
            ScrollView(.vertical) {
                if recordings.isEmpty {
                    ContentUnavailableView(
                        "No Recordings",
                        systemImage: "folder",
                        description: Text("Tap the Record button to start a Voice Note")
                    )
                    .padding(.top, 200)
                } else {
                    LazyVStack(alignment: .center, spacing: 0) {
                        ForEach(recordings) { recording in
                            RecordingRowView(
                                recording: recording,
                                isExpanded: vm.expandedRecording == recording.id,
                                hideRecordButton: $hideRecordButton
                            )
                            .contentShape(.rect)
                            .onTapGesture {
                                withAnimation(.smooth(duration: 0.2)) {
                                    if !vm.isEditing {
                                        if vm.expandedRecording != recording.id {
                                            vm.isPlaying = false
                                            vm.expandedRecording = recording.id
                                        }
                                    } else {
                                        vm.toggleSelection(for: recording.id)
                                    }
                                }
                                vm.setupPlayback(for: recording)
                            }
                        }
                        
                        Divider()
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                    }
                    .padding(.bottom, vm.isEditing ? 0 : size.height * 0.15)
                }
            }
        }
        .navigationTitle(navigationTitle!)
        .overlay(alignment: .bottom) {
            if !vm.isEditing && !hideRecordButton {
                Button {
                    vm.toggleRecording()
                } label: {
                    Image(systemName: "circle.fill")
                        .font(.largeTitle)
                }
                .buttonStyle(StartRecordButtonStyle())
                .transition(.move(edge: .bottom).combined(with: .blurReplace))
            }
        }
        .toolbar {
            if #available(iOS 26.0, *) {
                ToolbarItem {
                    Button {
                        
                    } label: {
                        Image(systemName: "magnifyingglass")
                    }
                }
                
                ToolbarSpacer(.fixed)
                
                ToolbarItem {
                    Button {
                        withAnimation(.snappy) {
                            vm.isEditing.toggle()
                        }
                    } label: {
                        Group {
                            if vm.isEditing {
                                Text("Cancel")
                            } else {
                                Text("Select")
                            }
                        }
                        .fontWeight(.medium)
                    }
                }
            } else {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        vm.isEditing.toggle()
                    } label: {
                        Text(vm.isEditing ? "Cancel" : "Edit")
                            .fontWeight(vm.isEditing ? .medium : .regular)
                            .contentTransition(.symbolEffect(.replace))
                            .animation(.smooth(duration: 0.1), value: vm.isEditing)
                    }
                    .disabled(recordings.isEmpty)
                }
            }
            
            if vm.isEditing {
                ToolbarItemGroup(placement: .bottomBar) {
                    let items = recordings.filter {
                        vm.selectedRecordings.contains($0.id)
                    }
                    
                    let fileNames = items.map { audio in
                        audio.fileName
                    }
  
                    ShareLink(items: getURLs(for: fileNames)) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                    
                    Spacer()
                    
                    Button {                      
                        vm.deleteRecording(from: items)
                        vm.isEditing = false
                    } label: {
                        Image(systemName: "trash")
                    }
                }
            }
        }
        .sheet(isPresented: $vm.hasStartedRecording) {
            RecordingSheet(folderTitle: navigationTitle!)
                .presentationDetents([.fraction(1)])
                .interactiveDismissDisabled(true)
                .presentationBackgroundInteraction(.disabled)
                .presentationDragIndicator(.hidden)
        }
        .sheet(isPresented: $vm.showOptionsSheet, onDismiss: vm.dismissOptionsSheet) {
            if let recording = recordings.first(where: { $0.id == vm.expandedRecording }) {
                OptionsSheet(recording: recording)
                    .presentationDetents([.large])
                    .presentationBackgroundInteraction(.automatic)
                    .presentationDragIndicator(.hidden)
            }
        }
        .animation(.smooth(duration: 0.2), value: vm.isEditing)
        .environment(vm)
    }
}

#Preview {
    NavigationStack {
        RecordingScreen(folderTitle: .all)
            .modelContainer(DIContainer.shared.makePreviewContainer())
    }
}

