//
//  RecordButtonStyle.swift
//  VoiceNotes
//
//  Created by Ziqa on 15/02/26.
//

import SwiftUI

struct RecordButtonStyle: ButtonStyle {
    let isRecording: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        if #available(iOS 26.0, *) {
            configuration.label
                .frame(width: 144, height: 64)
                .foregroundStyle(isRecording ? .white : .red)
                .font(isRecording ? .title2 : .title3)
                .fontWeight(.semibold)
                .background {
                    RoundedRectangle(cornerRadius: 50, style: .continuous)
                        .fill(isRecording ? .red : .white)
                }
                .glassEffect(.regular.interactive(true))
                .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
        } else {
            configuration.label
                .frame(width: 144, height: 64)
                .foregroundStyle(isRecording ? .white : .red)
                .font(isRecording ? .title2 : .title3)
                .fontWeight(.semibold)
                .background {
                    RoundedRectangle(cornerRadius: 50, style: .continuous)
                        .fill(isRecording ? .red : .white)
                }
                .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
                .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
        }
    }
}
