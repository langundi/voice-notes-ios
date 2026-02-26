//
//  ListRowButtonStyle.swift
//  VoiceNotes
//
//  Created by Ziqa on 26/02/26.
//

import SwiftUI

struct ListRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? .gray : .clear)
            .contentShape(.rect)
    }
}
