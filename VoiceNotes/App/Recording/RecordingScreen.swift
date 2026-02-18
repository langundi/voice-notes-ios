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
    
    @Namespace private var namespace
    
    @Environment(\.modelContext) private var context
    @Environment(\.editMode) private var editMode
    
    @Query var recordings: [AudioModel]
    
    var navigationTitle: String?
    
    init(folderTitle: String) {
        if folderTitle == "All" {
            _recordings = Query(sort: \.createdAt, order: .reverse, animation: .smooth(duration: 0.2))
            
            navigationTitle = "All Recordings"
        } else {
            let predicate = #Predicate<AudioModel> { audio in
                audio.Folder?.title == folderTitle
            }
            
            _recordings = Query(filter: predicate, sort: \.createdAt, order: .reverse, animation: .smooth(duration: 0.2))
            
            navigationTitle = folderTitle
        }
    }
    
    var body: some View {
        GeometryReader {
            let _ = $0.size
            let _ = $0.safeAreaInsets
            
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
                            RecordingRowView(recording: recording, isExpanded: vm.expandedRecording == recording.id)
                                .contentShape(.rect)
                                .onTapGesture {
                                    withAnimation(.smooth(duration: 0.2)) {
                                        if vm.expandedRecording != recording.id {
                                            vm.expandedRecording = recording.id
                                        }
                                    }
                                }
                        }
                        
                        Divider()
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                    }
                }
            }
            .navigationTitle(navigationTitle!)
            .overlay(alignment: .bottom) {
                if !vm.hasStartedRecording {
                    Button {
                        vm.toggleRecording()
                    } label: {
                        Image(systemName: "circle.fill")
                            .font(.largeTitle)
                    }
                    .buttonStyle(StartRecordButtonStyle())
                    .transition(.move(edge: .bottom).combined(with: .scale))
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
                            print(vm.selectedRecordings.count)
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
                            print(vm.selectedRecordings.count)
                            vm.isEditing.toggle()
                        } label: {
                            Text(vm.isEditing ? "Cancel" : "Edit")
                                .fontWeight(vm.isEditing ? .medium : .regular)
                                .animation(.smooth(duration: 0.1))
                                .disabled(recordings.isEmpty)
                        }
                    }
                }
            }
            .sheet(isPresented: $vm.hasStartedRecording) {
                RecordingSheet()
                    .presentationDetents([.fraction(1)])
                    .interactiveDismissDisabled(true)
                    .presentationBackgroundInteraction(.disabled)
                    .presentationDragIndicator(.hidden)
            }
            .environment(vm)
        }
    }
}

#Preview {
    NavigationStack {
        RecordingScreen(folderTitle: "All")
            .modelContainer(DIContainer.shared.makePreviewContainer())
    }
}

