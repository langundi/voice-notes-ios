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
    @State private var panGesture: UIPanGestureRecognizer?
    @State private var properties: SelectionProperties = .init()
    @State private var scrollProperties: ScrollProperties = .init()
    
    // Passed Parameters
    var navigationTitle: String?
    
    // Computed Properties
    private var selectedRecordings: [AudioModel] {
        let indices = properties.selectedIndices
        return vm.rowItems.enumerated()
            .filter { indices.contains($0.offset) }
            .map { $0.element.recording }
    }
    
    private var shareURLs: [URL] {
        let fileNames = selectedRecordings.map { $0.fileName }
        return getURLs(for: fileNames)
    }
    
    private var filteredRecordings: [AudioModel] {
        let text = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !text.isEmpty else { return Array(recordings) }
        
        return recordings.filter { recording in
            let title = recording.title
            return title.localizedStandardContains(text)
        }
    }
    
    init(folderTitle: FolderEnum) {
        switch folderTitle {
        case .all:
            _recordings = Query(
                sort: \.createdAt,
                order: .reverse,
                animation: .smooth(duration: K.animDuration)
            )
            
            navigationTitle = folderTitle.title
        case .favorites:
            let predicate = #Predicate<AudioModel> { state in
                state.isFavorite
            }
            
            _recordings = Query(
                filter: predicate,
                sort: \.createdAt,
                order: .reverse,
                animation: .smooth(duration: K.animDuration)
            )
            
            navigationTitle = folderTitle.title
        case .custom(let name):
            let predicate = #Predicate<AudioModel> { audio in
                audio.Folder?.title == name
            }
            
            _recordings = Query(
                filter: predicate,
                sort: \.createdAt,
                order: .reverse,
                animation: .smooth(duration: K.animDuration)
            )
            
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
                        ForEach(filteredRecordings) { recording in
                            if let index = vm.rowItems.firstIndex(where: { $0.id == recording.id }) {
                                RecordingRowView(
                                    rowItem: $vm.rowItems[index],
                                    index: index,
                                    isExpanded: vm.expandedRecording == recording.id,
                                    properties: $properties
                                )
                                .contentShape(.rect)
                                .onTapGesture {
                                    if !vm.isEditing {
                                        withAnimation(.smooth(duration: K.animDuration)) {
                                            if vm.expandedRecording != recording.id {
                                                vm.isPlaying = false
                                                vm.expandedRecording = recording.id
                                            }
                                        }
                                        
                                        vm.setupPlayback(for: recording)
                                    }
                                }
                                .overlay(alignment: .center) {
                                    if vm.isEditing {
                                        Rectangle()
                                            .foregroundStyle(.clear)
                                            .contentShape(.rect)
                                            .onTapGesture {
                                                withAnimation(.smooth(duration: K.animDuration)) {
                                                    if properties.selectedIndices.contains(index) {
                                                        properties.selectedIndices.removeAll { $0 == index }
                                                    } else {
                                                        properties.selectedIndices.append(index)
                                                    }
                                                    
                                                    properties.previousIndices = properties.selectedIndices
                                                }
                                            }
                                    }
                                }
                            }
                        }
                        .searchable(text: $searchText, isPresented: $isSearchActive, placement: .navigationBarDrawer, prompt: "Title, Date")
                        
                        Divider()
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                    }
                    .padding(.bottom, vm.isEditing ? 0 : size.height * 0.15)
                }
            }
            .scrollTargetLayout()
            .onScrollGeometryChange(for: CGFloat.self, of: { $0.contentOffset.y + $0.contentInsets.top }) { oldValue, newValue in
                scrollProperties.currentScrollOffset = newValue
            }
            .onChange(of: vm.isEditing) { oldValue, newValue in
                panGesture?.isEnabled = newValue
            }
            .onChange(of: scrollProperties.direction) { oldValue, newValue in
                // Scroll while dragging
                if newValue != .none {
                    guard scrollProperties.timer == nil else { return }
                    scrollProperties.manualScrollOffset = scrollProperties.currentScrollOffset
                    
                    scrollProperties.timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { _ in
                        if newValue == .up {
                            scrollProperties.manualScrollOffset += 15
                        }
                        
                        if newValue == .down {
                            scrollProperties.manualScrollOffset -= 15
                        }
                        
                        scrollProperties.position.scrollTo(y: scrollProperties.manualScrollOffset)
                    }
                    
                    scrollProperties.timer?.fire()
                } else {
                    resetTimer()
                }
            }
            .overlay(alignment: .leading) {
                // Area to drag select items
                GeometryReader { geo in
                    if vm.isEditing {
                        Rectangle()
                            .foregroundStyle(.clear)
                            .contentShape(.rect)
                            .frame(width: geo.size.width / 6)
                            .gesture(
                                PanGesture { gesture in
                                    if panGesture == nil {
                                        panGesture = gesture
                                        gesture.isEnabled = vm.isEditing
                                    }
                                    let state = gesture.state
                                    
                                    if state == .began || state == .changed {
                                        onGestureChange(gesture)
                                    } else {
                                        onGestureEnded(gesture)
                                    }
                                }
                            )
                    }
                }
            }
        }
        .scrollPosition($scrollProperties.position)
        .onChange(of: recordings) {
            vm.syncItems(recordings: recordings)
        }
        .task {
            vm.syncItems(recordings: recordings)
        }
        .overlay(alignment: .top) {
            ScrollDetectionRegion()
        }
        .overlay(alignment: .bottom) {
            ScrollDetectionRegion(false)
        }
        .overlay(alignment: .bottom) {
            if !vm.isEditing && !vm.hideRecordButton && !isSearchActive {
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
        .navigationTitle(navigationTitle!)
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
                                if !vm.isEditing {
                                    properties = .init()
                                }
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
                            
                            if !vm.isEditing {
                                properties = .init()
                            }
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
                    ShareLink(items: shareURLs) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                    .disabled(properties.selectedIndices.isEmpty)
                    
                    Spacer()
                    
                    Button {
                        vm.deleteRecording(from: selectedRecordings)
                        
                        properties = .init()
                        
                        vm.isEditing = false
                    } label: {
                        Image(systemName: "trash")
                    }
                    .disabled(properties.selectedIndices.isEmpty)
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
        .animation(.smooth(duration: K.animDuration), value: vm.isEditing)
        .environment(vm)
    }
    
    @ViewBuilder
    private func ScrollDetectionRegion(_ isTop: Bool = true) -> some View {
        Rectangle()
            .foregroundStyle(.clear)
            .frame(height: 100)
            .ignoresSafeArea()
            .onGeometryChange(for: CGRect.self) {
                $0.frame(in: .global)
            } action: { newValue in
                if isTop {
                    scrollProperties.topRegion = newValue
                } else {
                    scrollProperties.bottomRegion = newValue
                }
            }
    }
    
    private func onGestureChange(_ gesture: UIPanGestureRecognizer) {
        let position = gesture.location(in: gesture.view)
        if let fallingIndex = vm.rowItems.firstIndex(where: { $0.location.contains(position) }) {
            if properties.start == nil {
                properties.start = fallingIndex
                properties.isDeleteDrag = properties.previousIndices.contains(fallingIndex)
            }
            
            properties.end = fallingIndex
            
            if let start = properties.start, let end = properties.end {
                if properties.isDeleteDrag {
                    let indices = (start > end ? end...start : start...end).compactMap { $0 }
                    properties.toBeDeletedIndices = Set(properties.previousIndices).intersection(indices).compactMap({ $0 })
                } else {
                    let indices = (start > end ? end...start : start...end).compactMap { $0 }
                    properties.selectedIndices = Set(properties.previousIndices).union(indices).compactMap({ $0 })
                }
            }
            
            scrollProperties.direction = scrollProperties.topRegion.contains(position) ? .down : scrollProperties.bottomRegion.contains(position) ? .up : .none
        }
    }
    
    private func onGestureEnded(_ gesture: UIPanGestureRecognizer) {
        /// Deleting Indices that must be deleted
        for index in properties.toBeDeletedIndices {
            properties.selectedIndices.removeAll { $0 == index }
        }
        properties.toBeDeletedIndices = []
        
        properties.previousIndices = properties.selectedIndices
        properties.start = nil
        properties.end = nil
        properties.isDeleteDrag = false
        
        resetTimer()
    }
    
    private func resetTimer() {
        scrollProperties.manualScrollOffset = 0
        scrollProperties.timer?.invalidate()
        scrollProperties.timer = nil
        scrollProperties.direction = .none
    }
}

#Preview {
    NavigationStack {
        RecordingScreen(folderTitle: .all)
            .modelContainer(DIContainer.shared.makePreviewContainer())
    }
}

