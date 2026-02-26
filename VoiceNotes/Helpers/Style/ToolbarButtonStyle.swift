//
//  RecordButtonStyle.swift
//  VoiceNotes
//
//  Created by Ziqa on 15/02/26.
//

import SwiftUI

struct ToolBarButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        if #available(iOS 26.0, *) {
            configuration.label
                .frame(minWidth: 48, minHeight: 48)
                .foregroundStyle(.primary)
                .font(.title3)
                .glassEffect(.regular.interactive(true))
        } else {
            configuration.label
                .frame(minWidth: 48, minHeight: 48)
                .foregroundStyle(.blue)
                .font(.title2)
                .opacity(configuration.isPressed ? 0.4 : 1.0)
                .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
        }
    }
}
