//
//  ScrollProperties.swift
//  VoiceNotes
//
//  Created by Ziqa on 26/02/26.
//

import Foundation
import SwiftUI

/// Auto Scroll Properties
struct ScrollProperties {
    var position: ScrollPosition = .init()
    var currentScrollOffset: CGFloat = 0
    var manualScrollOffset: CGFloat = 0
    var timer: Timer?
    var direction: ScrollDirection = .none
    /// Regions
    var topRegion: CGRect = .zero
    var bottomRegion: CGRect = .zero
}

nonisolated
enum ScrollDirection {
    case up
    case down
    case none
}
