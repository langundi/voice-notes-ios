//
//  RecordButtonStyle.swift
//  VoiceNotes
//
//  Created by Ziqa on 15/02/26.
//

import SwiftUI

struct StartRecordButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        if #available(iOS 26.0, *) {
            configuration.label
                .frame(width: 72, height: 72)
                .foregroundStyle(.red)
                .fontWeight(.semibold)
                .background {
                    Circle()
                        .fill(.clear)
                }
                .glassEffect(.regular.interactive(true))
        } else {
            configuration.label
                .frame(width: 72, height: 72)
                .foregroundStyle(.red)
                .fontWeight(.semibold)
                .background {
                    Circle()
                        .fill(.white)
                }
                .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
                .shadow(color: .gray.opacity(0.2), radius: 15)
                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: configuration.isPressed)
        }
    }
}
