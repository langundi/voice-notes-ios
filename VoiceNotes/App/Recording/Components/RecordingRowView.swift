//
//  ItemRowView.swift
//  AudioRecorder
//
//  Created by Ziqa on 09/09/25.
//

import SwiftUI
import SwiftData

struct RecordingRowView: View {
    
    @Environment(RecordingViewModel.self) private var vm
    
    @State private var isSelected: Bool = false
    
    let recording: AudioModel
    
    var isExpanded: Bool
    
    var body: some View {
        @Bindable var vm = vm
        
        VStack(spacing: 12) {
            Divider()
            
            HStack(alignment: .center, spacing: 16) {
                titleAndDateView()
                
                Spacer()
                
                if isExpanded {
                    Button {
                        
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.title2)
                    }
                } else {
                    Text(format(time: recording.duration))
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .vSpacing(.bottom)
                        .transition(.push(from: .trailing).combined(with: .blurReplace))
                }
            }
            
            if isExpanded {
                playbackControlView()
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .animation(.snappy(duration: 0.3), value: [isExpanded])
    }
    
    @ViewBuilder
    private func titleAndDateView() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(recording.title)
                .fontWeight(.semibold)
                .lineLimit(1)
                .truncationMode(.tail)
            
            HStack(alignment: .center) {
                Text(format(date: recording.createdAt, format: "HH.mm"))
                    .font(.callout)
                
                Image(systemName: "quote.bubble")
                    .font(.title3)
            }
            .foregroundStyle(.secondary)
        }
    }
    
    @ViewBuilder
    private func playbackControlView() -> some View {
        VStack(alignment: .center, spacing: 4) {
            RoundedRectangle(cornerRadius: 50)
                .fill(.quaternary)
                .frame(maxWidth: .infinity, maxHeight: 6)
                .padding(.top, 24)
            
            HStack {
                Text(format(time: vm.duration))
                
                Spacer()
                
                Text(format(time: recording.duration))
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            
            HStack(alignment: .center, spacing: 36) {
                Button {
                    // Open sheet
                } label: {
                    Image(systemName: "waveform")
                        .fontWeight(.light)
                        .foregroundStyle(.blue)
                }
                
                Spacer()
                
                Button {
                    // Rewind 15 seconds
                } label: {
                    Image(systemName: "15.arrow.trianglehead.counterclockwise")
                }
                
                Button {
                    // Toggle playback
                } label: {
                    Image(systemName: vm.isPlaying ? "pause.fill" : "play.fill")
                        .font(.largeTitle)
                }
                .frame(maxWidth: 40, maxHeight: 40)
                
                Button {
                    // Fast forward 15 seconds
                } label: {
                    Image(systemName: "15.arrow.trianglehead.clockwise")
                }
                
                Spacer()
                
                Button {
                    // Delete
                } label: {
                    Image(systemName: "trash")
                        .fontWeight(.light)
                        .foregroundStyle(.blue)
                }
            }
            .font(.title2)
            .fontWeight(.medium)
            .foregroundStyle(.primary)
            .padding(.top, 24)
        }
        .transition(.move(edge: .top).combined(with: .blurReplace))
    }
}

#Preview {
    let vm = DIContainer.shared.makeRecordingViewModel()
    
    ScrollView {
        RecordingRowView(recording: AudioModel.sample, isExpanded: true)
        RecordingRowView(recording: AudioModel.sample, isExpanded: false)
    }
    .modelContainer(DIContainer.shared.makePreviewContainer())
    .environment(vm)
    
}

//if vm.isEditing {
//                    Button {
//                        if isSelected {
//
//                        } else {
//
//                        }
//                        isSelected.toggle()
//                    } label: {
//                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
//                            .font(.title3)
//                    }
//                    .transition(.move(edge: .leading).combined(with: .opacity))
//                }
