//
//  OptionsSheet.swift
//  VoiceNotes
//
//  Created by Ziqa on 23/02/26.
//

import SwiftUI

struct OptionsSheet: View {
    
    @Environment(RecordingViewModel.self) private var vm
    
    @State private var rate: Float = 1.0
    @State private var skipSilenceOn: Bool = false
    @State private var enhanceRecordingOn: Bool = false
    @State private var defaultSettings: Bool = true
    
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
                        
                        Toggle("Skip Silence", isOn: $vm.skipSilenceOn)
                    }
                    
                    Toggle("Enhance Recording", isOn: $vm.enhanceRecordingOn)
                }
                .listSectionSpacing(16)
            }
            .navigationTitle("Options")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Reset") {
                        withAnimation(.snappy(duration: 0.2)) {
                            defaultSettings = true
                            enhanceRecordingOn = false
                            skipSilenceOn = false
                            rate = 1.0
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
            .onChange(of: enhanceRecordingOn) { _, newValue in
                defaultSettings = !newValue
            }
            .onChange(of: skipSilenceOn) { _, newValue in
                defaultSettings = !newValue
            }
            .onChange(of: vm.rate) { _, newValue in
                defaultSettings = newValue == 1.0
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
