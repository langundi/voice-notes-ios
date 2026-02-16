//
//  ExpandedRecordingSheet.swift
//  VoiceNotes
//
//  Created by Ziqa on 15/02/26.
//

import SwiftUI

struct RecordingSheet: View {
    
    @Environment(RecordingViewModel.self) private var vm
    
    var body: some View {
        @Bindable var vm = vm
        
        NavigationStack {
            VStack(spacing: 16) {
                Text("New Recording 12")
                    .font(.title2)
                    .fontWeight(.bold)
                
                HStack(alignment: .center, spacing: 8) {
                    Text("28 Nov 2024")
                        .foregroundStyle(.secondary)
                        .fontWeight(.semibold)
                    
                    Text("20.00")
                        .foregroundStyle(.gray)
                }
                
                Spacer()
                
                HStack {
                    Button {
                        
                    } label: {
                        Image(systemName: "quote.bubble")
                    }
                    .buttonStyle(ToolBarButtonStyle())
                    
                    Spacer()
                    
                    Button {
                        vm.toggleRecording()
                    } label: {
                        Group {
                            if vm.isRecording {
                                Image(systemName: "pause.fill")
                            } else {
                                Text("RESUME")
                            }
                        }
                        .transition(.blurReplace)
                    }
                    .buttonStyle(RecordButtonStyle(isRecording: vm.isRecording))
                    
                    Spacer()
                    
                    Button {
                        vm.stopRecording()
                    } label: {
                        Group {
                            if #available(iOS 26, *) {
                                Image(systemName: "stop.fill")
                            } else {
                                Image(systemName: "stop.circle")
                                    .font(.title)
                            }
                        }
                        .foregroundStyle(.red)
                    }
                    .buttonStyle(ToolBarButtonStyle())
                }
                .padding(.horizontal, 36)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("", systemImage: "ellipsis") { }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("", systemImage: "checkmark") { }
                }
            }
            .background(.gray.opacity(0.05))
        }
    }
}

#Preview {
    let vm = DIContainer.shared.makeRecordingViewModel()
    RecordingSheet()
        .environment(vm)
}
