//
//  HomeScreen.swift
//  VoiceNotes
//
//  Created by Ziqa on 14/02/26.
//

import SwiftUI
import SwiftData

struct HomeScreen: View {
    
    @State private var vm = DIContainer.shared.makeHomeViewModel()
    
    @Environment(\.modelContext) private var context
    @Environment(\.editMode) private var editMode
    
    @AppStorage(K.microphoneAccess)
    private var microphoneAccess: MicrophoneAccessEnum = .undetermined
    
    @Query(animation: .snappy) var recordings: [AudioModel]
    @Query(animation: .snappy) var folders: [FolderModel]
    @Query(filter: #Predicate<AudioModel> {
        $0.isFavorite
    }, animation: .snappy) var favorites: [AudioModel]
    
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .center, spacing: 16) {
                List {
                    NavigationLink {
                        RecordingScreen(folderTitle: .all)
                    } label: {
                        HStack(spacing: 16) {
                            Image(systemName: "waveform")
                                .fontWeight(.light)
                                .font(.title3)
                                .foregroundStyle(.blue)
                            
                            Text("All Recordings")
                            
                            Spacer()
                            
                            Text("\(recordings.count)")
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    if !favorites.isEmpty {
                        NavigationLink {
                            RecordingScreen(folderTitle: .favorites)
                        } label: {
                            HStack(spacing: 16) {
                                Image(systemName: "heart")
                                    .fontWeight(.light)
                                    .font(.title3)
                                    .foregroundStyle(.blue)
                                
                                Text("Favorites")
                                
                                Spacer()
                                
                                Text("\(favorites.count)")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    
                    Section(folders.isEmpty ? "" : "My Folders") {
                        ForEach(folders) { folder in
                            let count = folder.Audios.count
                            
                            NavigationLink {
                                RecordingScreen(folderTitle: .custom(folder.title))
                            } label: {
                                HStack(spacing: 16) {
                                    Image(systemName: "folder")
                                        .fontWeight(.light)
                                        .font(.title3)
                                        .foregroundStyle(.blue)
                                    
                                    Text(folder.title)
                                    
                                    Spacer()
                                    
                                    Text("\(count)")
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .onDelete { index in
                            for offset in index {
                                let folder = folders[offset]
                                vm.deleteFolder(folder: folder)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Voice Notes")
            .toolbar {
                ToolbarItem {
                    Button {
                        vm.showAlert = true
                    } label: {
                        Image(systemName: "folder.badge.plus")
                    }
                    .disabled(vm.isEditing)
                }
                
                if #available(iOS 26.0, *) {
                    ToolbarSpacer(.fixed)
                    
                    ToolbarItem {
                        Button {
                            vm.isEditing.toggle()
                        } label: {
                            Group {
                                if vm.isEditing {
                                    Image(systemName: "checkmark")
                                } else {
                                    Text("Edit")
                                        .padding(.horizontal, 4)
                                }
                            }
                            .fontWeight(.medium)
                        }
                    }
                } else {
                    ToolbarItemGroup(placement: .bottomBar) {
                        Spacer()
                        
                        Button {
                            vm.isEditing.toggle()
                        } label: {
                            Text(vm.isEditing ? "Done" : "Edit")
                                .contentTransition(.symbolEffect(.replace))
                        }
                    }
                }
            }
            .alert("New Folder", isPresented: $vm.showAlert) {
                TextField("Name", text: $vm.newFolderTitle)
                    .onChange(of: vm.newFolderTitle) { newValue, _ in
                        if newValue.count > 50 {
                            vm.newFolderTitle = String(newValue.prefix(50))
                        }
                    }
                
                Button("Cancel", role: .cancel) {
                    vm.resetAlert()
                }
                
                if #available(iOS 26.0, *) {
                    Button("Add", role: .confirm) {
                        vm.createNewFolder()
                    }
                    .keyboardShortcut(.defaultAction)
                    .disabled(vm.newFolderTitle.isEmpty)
                } else {
                    Button("Add") {
                        vm.createNewFolder()
                    }
                    .disabled(vm.newFolderTitle.isEmpty)
                }
            } message: {
                Text("Enter a name for this folder.")
            }
            .alert("Microphone Access Needed", isPresented: $vm.showMicrophoneAlert) {
                Button("Cancel", role: .cancel) {
                    vm.showMicrophoneAlert = false
                }
                
                if #available(iOS 26.0, *) {
                    Button("OK", role: .confirm) {
                        vm.showMicrophoneAlert = false
                    }
                    .keyboardShortcut(.defaultAction)
                } else {
                    Button("OK") {
                        vm.showMicrophoneAlert = false
                    }
                }
            } message: {
                Text("This app uses microphone to record audio. Enable microphone permissions in Settings>Voice Notes>Microphone Permission.")
            }
            .task {
                vm.checkMicrophonePermission()
                if vm.microphoneAccess == .undetermined {
                    await vm.requestMicrophonePermissions()
                    print("microphone: \(microphoneAccess)")
                }
                
                microphoneAccess = vm.microphoneAccess
                
                if microphoneAccess == .granted {
//                    microphoneAccess = vm.microphoneAccess
                    vm.setupAudioSession()
                    print("microphone: \(microphoneAccess)")
                } else if microphoneAccess == .denied {
//                    microphoneAccess = vm.microphoneAccess
                    vm.showMicrophoneAlert = true
                    print("microphone: \(microphoneAccess)")
                }
            }
            .animation(.smooth(duration: K.animDuration), value: vm.isEditing)
            .environment(\.editMode, .constant(vm.isEditing ? .active : .inactive))
        }
    }
}

#Preview {
    NavigationStack {
        HomeScreen()
            .modelContainer(DIContainer.shared.makePreviewContainer())
    }
}
