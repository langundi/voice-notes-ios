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
    
    @Environment(\.modelContext) private var context
    @Environment(\.editMode) private var editMode
    
    @Query(sort: \AudioModel.createdAt, order: .reverse, animation: .smooth(duration: 0.2))
    var recordings: [AudioModel]
    
    @Namespace private var namespace
    
    var body: some View {
        GeometryReader {
            let _ = $0.size
            let _ = $0.safeAreaInsets
            
            ScrollView(.vertical) {
                LazyVStack(alignment: .center, spacing: 8) {
                    recordingList()
                }
            }
            .navigationTitle("Recordings")
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
                        } label: {
                            Group {
                                if vm.isEditing {
                                    Text("Select")
                                } else {
                                    Text("Cancel")
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
                                .animation(.smooth(duration: 0.1))
                        }
                    }
                }
            }
            .sheet(isPresented: $vm.hasStartedRecording) {
                RecordingSheet()
                    .environment(vm)
                    .presentationDetents([.fraction(1)])
                    .interactiveDismissDisabled(true)
                    .presentationBackgroundInteraction(.disabled)
                    .presentationDragIndicator(.hidden)
            }
        }
    }
    
    @ViewBuilder
    private func recordingList() -> some View {
        ForEach(recordings) { recording in
            Text(recording.title)
                .padding()
        }
    }
}

#Preview {
    RecordingScreen()
        .modelContainer(DIContainer.shared.makePreviewContainer())
}

