//
//  OptionsSheet.swift
//  VoiceNotes
//
//  Created by Ziqa on 23/02/26.
//

import SwiftUI

struct OptionsSheet: View {
    
    @Environment(RecordingViewModel.self) private var vm
    
    let recording: AudioModel
    
    var body: some View {
        @Bindable var vm = vm
        
        NavigationStack {
            VStack {
                List {
                    Section("Playback Speed") {
                        Slider(
                            value: $vm.rate,
                            in: 0.5...2.0,
                            step: 0.25
                        ) {
                            Text("Speed")
                        } minimumValueLabel: {
                            Image(systemName: "tortoise")
                        } maximumValueLabel: {
                            Image(systemName: "hare")
                        }
                        .contentTransition(.symbolEffect)
                    }
                }
                .listSectionSpacing(16)
            }
            .navigationTitle("Options")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Reset") {
                        withAnimation(.snappy(duration: K.animDuration)) {
                            vm.defaultSettings = true
                            vm.resetPlaybackOptions(for: recording)
                        }
                    }
                    .disabled(vm.defaultSettings)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("", systemImage: "checkmark") {
                        vm.showOptionsSheet = false
                    }
                }
            }
            .onAppear {
                vm.updateOptionsState(for: recording)
            }
            .onChange(of: vm.rate) { _, newValue in
                vm.defaultSettings = newValue == 1.0
                vm.changeRate(to: newValue)
                vm.updateRate(for: recording, newRate: newValue)
                print("Playback rate: \(vm.rate)")
            }
        }
    }
}

#Preview {
    OptionsSheet(recording: AudioModel.sample)
}
