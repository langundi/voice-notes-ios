//
//  RecordingScreen.swift
//  VoiceNotes
//
//  Created by Ziqa on 14/02/26.
//

import SwiftUI
import SwiftData

struct RecordingScreen: View {
    
    @Namespace private var namespace
    
    @Query var recordings: [AudioModel]
    
    @Environment(\.modelContext) private var context
    @Environment(\.editMode) private var editMode
    
    @State private var vm = DIContainer.shared.makeRecordingViewModel()
    @State private var searchText: String = ""
    @State private var isSearchActive: Bool = false
    
    // Passed Parameters
    var navigationTitle: String?
    var folderTitle: FolderEnum?
    
    // Computed Properties
    private var selectedRecordings: [AudioModel] {
        recordings.filter { vm.selectedRecordings.contains($0.id) }
    }
    
    private var shareURLs: [URL] {
        let fileNames = selectedRecordings.map { $0.fileName }
        return getURLs(for: fileNames)
    }
    
    private var filteredRecordings: [AudioModel] {
        let text = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !text.isEmpty else { return Array(recordings) }
        
        return recordings.filter { recording in
            let title = recording.title.localizedStandardContains(text)
            let month = formatDate(date: recording.createdAt).localizedStandardContains(text)
            return title || month
        }
    }
    
    init(folderTitle: FolderEnum) {
        switch folderTitle {
        case .all:
            let predicate = #Predicate<AudioModel> {
                !$0.isDeleted
            }
            
            _recordings = Query(
                filter: predicate,
                sort: \.createdAt,
                order: .reverse,
                animation: .smooth(duration: K.animDuration)
            )
            
            navigationTitle = folderTitle.title
            self.folderTitle = folderTitle
        case .favorites:
            let predicate = #Predicate<AudioModel> {
                $0.isFavorite && !$0.isDeleted
            }
            
            _recordings = Query(
                filter: predicate,
                sort: \.createdAt,
                order: .reverse,
                animation: .smooth(duration: K.animDuration)
            )
            
            navigationTitle = folderTitle.title
            self.folderTitle = folderTitle
        case .custom(let name):
            let predicate = #Predicate<AudioModel> {
                $0.Folder?.title == name && !$0.isDeleted
            }
            
            _recordings = Query(
                filter: predicate,
                sort: \.createdAt,
                order: .reverse,
                animation: .smooth(duration: K.animDuration)
            )
            
            navigationTitle = name
            self.folderTitle = folderTitle
        case .trash:
            let predicate = #Predicate<AudioModel> {
                $0.isDeleted
            }
            
            _recordings = Query(
                filter: predicate,
                sort: \.createdAt,
                order: .reverse,
                animation: .smooth(duration: K.animDuration)
            )
            
            navigationTitle = folderTitle.title
            self.folderTitle = folderTitle
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
                        ForEach(filteredRecordings) { recording in
                            RecordingRowView(
                                recording: recording,
                                isExpanded: vm.expandedRecording == recording.id,
                            )
                            .contentShape(.rect)
                            .onTapGesture {
                                withAnimation(.smooth(duration: K.animDuration)) {
                                    if !vm.isEditing {
                                        if vm.expandedRecording != recording.id {
                                            vm.isPlaying = false
                                            vm.expandedRecording = recording.id
                                        }
                                        vm.setupPlayback(for: recording)
                                    } else {
                                        vm.toggleSelection(for: recording.id)
                                    }
                                }
                            }
                        }
                        
                        Divider()
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                    }
                    .padding(.bottom, vm.isEditing ? 0 : size.height * 0.15)
                }
            }
            .navigationTitle(navigationTitle!)
            .searchable(
                text: $searchText,
                isPresented: $isSearchActive,
                placement: .navigationBarDrawer,
                prompt: "Title, Date"
            )
            .overlay(alignment: .bottom) {
                if !vm.isEditing && !vm.hideRecordButton && !isSearchActive && folderTitle?.title != FolderEnum.trash.title {
                    Button {
                        Task {
                            await vm.toggleRecording()
                        }
                    } label: {
                        Circle()
                            .fill(.red)
                            .frame(width: 64, height: 64)
                    }
                    .buttonStyle(StartRecordButtonStyle())
                    .transition(.move(edge: .bottom).combined(with: .blurReplace))
                }
            }
            .toolbar {
                if !recordings.isEmpty {
                    if #available(iOS 26.0, *) {
                        ToolbarItem {
                            Button {
                                isSearchActive.toggle()
                            } label: {
                                Image(systemName: "magnifyingglass")
                            }
                        }
                        
                        ToolbarSpacer(.fixed)
                        
                        ToolbarItem {
                            Button {
                                withAnimation(.smooth(duration: K.animDuration)) {
                                    vm.isEditing.toggle()
                                }
                            } label: {
                                Text(vm.isEditing ? "Cancel" : "Select")
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
                            }
                            .disabled(recordings.isEmpty)
                        }
                    }
                }
                
                if vm.isEditing {
                    ToolbarItemGroup(placement: .bottomBar) {
                        if folderTitle?.title == FolderEnum.trash.title {
                            Button("Recover") {
                                vm.recoverRecordings(for: selectedRecordings)
                                vm.isEditing = false
                            }
                        } else {
                            ShareLink(items: shareURLs) {
                                Label("Share", systemImage: "square.and.arrow.up")
                            }
                            .disabled(selectedRecordings.isEmpty)
                        }
                        
                        
                        Spacer()
                        
                        if folderTitle?.title == FolderEnum.trash.title {
                            Button("Delete") {
                                vm.deleteRecording(for: selectedRecordings)
                                vm.isEditing = false
                            }
                        } else {
                            Button {
                                vm.moveToTrash(for: selectedRecordings)
                                vm.isEditing = false
                            } label: {
                                Image(systemName: "trash")
                            }
                            .disabled(selectedRecordings.isEmpty)
                        }
                    }
                }
            }
            .sheet(isPresented: $vm.showRecordingSheet) {
                if vm.expandedRecording == nil {
                    RecordingSheet(folderTitle: navigationTitle!)
                        .presentationDetents([.fraction(1)])
                        .interactiveDismissDisabled(true)
                        .presentationBackgroundInteraction(.disabled)
                        .presentationDragIndicator(.hidden)
                } else {
                    if let recording = recordings.first(where: { $0.id == vm.expandedRecording }) {
                        RecordingSheet(folderTitle: navigationTitle!, recording: recording)
                            .presentationDetents([.fraction(1)])
                            .interactiveDismissDisabled(true)
                            .presentationBackgroundInteraction(.disabled)
                            .presentationDragIndicator(.hidden)
                    }
                }
            }
            .sheet(isPresented: $vm.showOptionsSheet) {
                if let recording = recordings.first(where: { $0.id == vm.expandedRecording }) {
                    OptionsSheet(recording: recording)
                        .presentationDetents([.large])
                        .presentationBackgroundInteraction(.disabled)
                        .presentationDragIndicator(.hidden)
                }
            }
            .sheet(isPresented: $vm.showSelectFolderSheet) {
                if let recording = recordings.first(where: { $0.id == vm.expandedRecording }) {
                    SelectFolderSheet(recording: recording)
                        .presentationDetents([.large])
                        .presentationBackgroundInteraction(.disabled)
                        .presentationDragIndicator(.hidden)
                }
            }
            .onDisappear {
                vm.stopAudio()
            }
            .onChange(of: vm.isRecording, { oldValue, newValue in
                if newValue == true {
                    withAnimation(.smooth(duration: K.animDuration)) {
                        vm.expandedRecording = nil
                    }
                }
            })
            .animation(.smooth(duration: K.animDuration), value: vm.isEditing)
            .animation(.smooth(duration: K.animDuration), value: vm.hideRecordButton)
            .environment(vm)
        }
    }
}

#Preview {
    NavigationStack {
        RecordingScreen(folderTitle: .all)
            .modelContainer(DIContainer.shared.makePreviewContainer())
    }
}

