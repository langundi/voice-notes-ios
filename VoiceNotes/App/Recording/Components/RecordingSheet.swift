//
//  ExpandedRecordingSheet.swift
//  VoiceNotes
//
//  Created by Ziqa on 15/02/26.
//

import SwiftUI

struct RecordingSheet: View {
    
    @Environment(RecordingViewModel.self) private var vm
    
    @ScaledMetric private var buttonWidth: CGFloat = 44
    
    let folderTitle: String
    
    var body: some View {
        @Bindable var vm = vm
        
        NavigationStack {
            VStack(spacing: 24) {
                Text(vm.title ?? "Title")
                    .font(.title2)
                    .fontWeight(.bold)
                
                HStack(alignment: .center, spacing: 8) {
                    Text("\(formatDate(date: vm.createdAt ?? Date.now, format: "dd MMM yyyy"))")
                        .foregroundStyle(.secondary)
                        .fontWeight(.semibold)
                    
                    Text("\(formatTime(time: vm.currentTime))")
                        .foregroundStyle(.gray)
                        .monospacedDigit()
                }
                .frame(maxWidth: .infinity)
                
                Rectangle()
                    .fill(.gray.tertiary)
                    .frame(height: 320)
                    .padding(.bottom, 24)
                
                Text("\(formatTimer(time: vm.currentTime))")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .monospacedDigit()
                
                HStack(spacing: 32) {
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
                            .animation(.smooth, value: vm.isPlaying)
                            .frame(width: buttonWidth)
                    }
                    
                    Button {
                        vm.forward15Seconds()
                    } label: {
                        Image(systemName: "15.arrow.trianglehead.clockwise")
                    }
                }
                .font(.title)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
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
                        if folderTitle == "Favorites" {
                            vm.saveRecordingForFavorites()
                        } else {
                            vm.saveRecording()
                        }
                        vm.dismissRecordingSheet()
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
    RecordingSheet(folderTitle: "All Recordings")
        .environment(vm)
}
