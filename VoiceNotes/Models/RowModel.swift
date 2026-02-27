//
//  RowModel.swift
//  VoiceNotes
//
//  Created by Ziqa on 26/02/26.
//

import SwiftUI

struct RowModel: Hashable, Identifiable {
    var id: AudioModel.ID
    var recording: AudioModel
    var location: CGRect = .zero
}
