//
//  OptionsSheet.swift
//  VoiceNotes
//
//  Created by Ziqa on 23/02/26.
//

import SwiftUI

struct OptionsSheet: View {
    
    @State private var speed: Double = 1.0
    @State private var skipSilenceOn: Bool = false
    @State private var enhanceRecordingOn: Bool = false
    @State private var defaultSettings: Bool = true
    
    var body: some View {
        NavigationStack {
            VStack {
                List {
                    Section("Playback Speed") {
                        Slider(
                            value: $speed,
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
                        
                        Toggle("Skip Silence", isOn: $skipSilenceOn)
                    }
                    
                    Toggle("Enhance Recording", isOn: $enhanceRecordingOn)
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
                            speed = 1.0
                        }
                    }
                    .disabled(defaultSettings)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("", systemImage: "checkmark") {
                        
                    }
                }
            }
            .onChange(of: enhanceRecordingOn) { _, newValue in
                defaultSettings = !newValue
            }
            .onChange(of: skipSilenceOn) { _, newValue in
                defaultSettings = !newValue
            }
            .onChange(of: speed) { _, newValue in
                defaultSettings = newValue == 1.0
            }
        }
    }
}

#Preview {
    OptionsSheet()
}
