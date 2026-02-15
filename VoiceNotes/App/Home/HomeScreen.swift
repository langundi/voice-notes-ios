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
    
    @Query(animation: .snappy) var recordings: [AudioModel]
    @Query(animation: .snappy) var folders: [FolderModel]
    
    var body: some View {
        VStack(alignment: .center, spacing: 16) {
            List {
                NavigationLink {
                    RecordingScreen()
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
                
                Section(folders.isEmpty ? "" : "My Folders") {
                    ForEach(folders) { folder in
                        let count = folder.Audios.count
                        
                        NavigationLink {
                            RecordingScreen()
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
                        withAnimation(.snappy) {
                            vm.isEditing.toggle()
                        }
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
                            .animation(.smooth(duration: 0.1))
                    }
                }
            }
        }
        .alert("Create New Folder", isPresented: $vm.showAlert) {
            TextField("New Folder", text: $vm.newFolderTitle)
                .onChange(of: vm.newFolderTitle) { newValue, _ in
                    if newValue.count > 50 {
                        vm.newFolderTitle = String(newValue.prefix(50))
                    }
                }
            
            Button("Cancel", role: .cancel) {
                print("Cancel pressed")
                vm.resetAlert()
            }
            
            if #available(iOS 26.0, *) {
                Button("Add", role: .confirm) {
                    print("Add pressed")
                    vm.createNewFolder()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(vm.newFolderTitle.isEmpty)
            } else {
                Button("Add") {
                    print("Add pressed")
                    vm.createNewFolder()
                }
                .disabled(vm.newFolderTitle.isEmpty)
            }
        }
        .environment(\.editMode, .constant(vm.isEditing ? .active : .inactive))
    }
}

#Preview {
    NavigationStack {
        HomeScreen()
    }
}
