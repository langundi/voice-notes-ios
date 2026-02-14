//
//  RecordingScreen.swift
//  VoiceNotes
//
//  Created by Ziqa on 14/02/26.
//

import SwiftUI

struct RecordingScreen: View {
    
    @State private var vm = DIContainer.shared.makeRecordingViewModel()
    
    var body: some View {
        Text("Hello")
    }
}

#Preview {
    RecordingScreen()
}
