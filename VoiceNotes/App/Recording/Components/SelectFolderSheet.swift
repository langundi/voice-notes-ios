//
//  SelectFolderSheet.swift
//  VoiceNotes
//
//  Created by Ziqa on 26/02/26.
//

import SwiftUI
import SwiftData

struct SelectFolderSheet: View {
    
    @Environment(RecordingViewModel.self) private var vm
    
    @Query(animation: .snappy) var recordings: [AudioModel]
    @Query(filter: #Predicate<AudioModel> {
        $0.isFavorite
    }, animation: .snappy) var favorites: [AudioModel]
    @Query(filter: #Predicate<AudioModel> {
        $0.isDeleted
    }, animation: .snappy) var deleted: [AudioModel]
    @Query(animation: .snappy) var folders: [FolderModel]
    
    var body: some View {
        @Bindable var vm = vm
        
        NavigationStack {
            VStack(alignment: .center, spacing: 16) {
                List {
                    Group {
                        Button {
                            print("test")
                        } label: {
                            ListRow(symbol: "waveform", title: "All Recordings", count: recordings.count)
                        }
                        
                        if !favorites.isEmpty {
                            Button {
                                
                            } label: {
                                ListRow(symbol: "heart", title: "Favorites", count: favorites.count)
                            }
                        }
                        
                        if !deleted.isEmpty {
                            Button {
                                
                            } label: {
                                ListRow(symbol: "trash", title: "Recently Deleted", count: deleted.count)
                            }
                        }
                    }
                    .foregroundStyle(.primary)
                    
                    if !folders.isEmpty {
                        Section("My Folders") {
                            ForEach(folders) { folder in
                                Button {
                                    
                                } label: {
                                    ListRow(symbol: "folder", title: folder.title, count: folder.Audios.count)
                                }
                                .foregroundStyle(.primary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select a Folder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("", systemImage: "xmark") {
                        vm.showSelectFolderSheet = false
                    }
                }
                
                ToolbarItemGroup(placement: .bottomBar) {
                    Spacer()
                    
                    Button("", systemImage: "folder.badge.plus") {
                        
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func ListRow(symbol: String, title: String, count: Int) -> some View {
        HStack(spacing: 16) {
            Image(systemName: symbol)
                .fontWeight(.light)
                .font(.title3)
                .foregroundStyle(.blue)
            
            Text(title)
            
            Spacer()
            
            Text("\(count)")
                .foregroundStyle(.secondary)
        }
    }
        
}

#Preview {
    let vm = DIContainer.shared.makeRecordingViewModel()
    SelectFolderSheet()
        .modelContainer(DIContainer.shared.makePreviewContainer())
        .environment(vm)
}
