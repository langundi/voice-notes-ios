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
    
    @State private var showTranscription: Bool = false
    
    let folderTitle: String
    
    var body: some View {
        @Bindable var vm = vm
        
        NavigationStack {
            VStack(spacing: 24) {
                SheetHeader()
                
                if showTranscription {
                    TranscriptionView()
                        .frame(maxHeight: .infinity, alignment: .top)
                        .padding(.bottom, 24)
                } else {
                    Rectangle()
                        .fill(.gray.secondary)
                        .frame(maxHeight: .infinity)
                        .padding(.bottom, 24)
                }
                
                SheetControls()
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
    
    @ViewBuilder
    private func SheetHeader() -> some View {
        VStack(spacing: 2) {
            Text(vm.title ?? "Title")
                .font(.title2)
                .fontWeight(.bold)
            
            HStack(alignment: .center, spacing: 8) {
                Text("\(formatDate(date: vm.createdAt ?? Date.now))")
                    .foregroundStyle(.secondary)
                    .fontWeight(.semibold)
                
                Text("\(formatTime(time: vm.currentTime))")
                    .foregroundStyle(.gray)
                    .monospacedDigit()
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    @ViewBuilder
    private func TranscriptionView() -> some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical) {
                if !vm.transcriptionModel.displayText.isEmpty {
                    Text(vm.transcriptionModel.displayText)
                        .font(.title3)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                        .padding(.horizontal, 36)
                        .id("transcriptionText")
                } else {
                    EmptyView()
                }
            }
            .onChange(of: vm.transcriptionModel.displayText) { _, _ in
                withAnimation {
                    proxy.scrollTo("transcriptionText", anchor: .bottom)
                }
            }
        }
    }
    
    @ViewBuilder
    private func SheetControls() -> some View {
        VStack(spacing: 36) {
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
                        .animation(.smooth(duration: K.animDuration), value: vm.isPlaying)
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
            .frame(maxWidth: .infinity)
            
            HStack {
                Button {
                    showTranscription.toggle()
                } label: {
                    Image(systemName: "quote.bubble")
                }
                .buttonStyle(ToolBarButtonStyle())
                
                Spacer()
                
                Button {
                    Task {
                        await vm.toggleRecording()
                    }
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
                    Task {
                        await vm.stopRecording()
                    }
                    
                    if folderTitle == "Favorites" {
                        vm.saveRecordingForFavorites()
                    } else if folderTitle == "All Recordings" {
                        vm.saveRecording()
                    } else {
                        vm.saveRecordingToFolder(folderTitle: folderTitle)
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
    }
}

#Preview {
    let vm = DIContainer.shared.makeRecordingViewModel()
    RecordingSheet(folderTitle: "All Recordings")
        .environment(vm)
}
