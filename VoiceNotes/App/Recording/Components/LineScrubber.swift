//
//  LineScrubber.swift
//  VoiceNotes
//
//  Created by Ziqa on 03/03/26.
//

import SwiftUI

struct LineScrubber: View {
    var config: Config = .init()
    @Binding var current: TimeInterval
    var total: TimeInterval
    var onEditingChanged: ((Bool) -> Void)? = nil
    var onScrub: ((TimeInterval) -> Void)? = nil
    
    @State private var viewSize: CGSize = .zero
    @State private var lastProgress: CGFloat = 0
    @GestureState private var isActive: Bool = false
    
    private var progress: CGFloat {
        guard total > 0 else { return 0 }
        
        // Converts current time into CGFloat value
        // Set clamped value of 0 - 1
        return max(0, min(CGFloat(current / total), 1))
    }
    
    var body: some View {
        ZStack(alignment: .leading) {
            Capsule()
                .fill(config.inActiveTint)
                .frame(height: config.trackHeight)
            
            Capsule()
                .fill(config.activeTint)
                .frame(width: max(0, viewSize.width * progress), height: config.trackHeight)
        }
        .frame(maxWidth: .infinity)
        .contentShape(.rect)
        .gesture(
            DragGesture()
                .updating($isActive) { _, out, _ in
                    out = true
                }
                .onChanged { value in
                    // Combine lastProgress with how far finger has moved
                    // Converts to the track width of CGFloat (0–1)
                    let p = max(min((value.translation.width / viewSize.width) + lastProgress, 1), 0)
                    
                    // Converts CGFloat (0-1) to real time value
                    current = TimeInterval(p) * total
                    
                    onEditingChanged?(true)
                    onScrub?(current)
                }
                .onEnded { _ in
                    lastProgress = progress
                    onEditingChanged?(false)
                }
        )
        .onTapGesture { location in
            let x = max(min((location.x / viewSize.width), 1), 0)
            current = TimeInterval(x) * total
            onEditingChanged?(true)
            onScrub?(current)
            onEditingChanged?(false)
        }
        .onGeometryChange(for: CGSize.self) {
            $0.size
        } action: { newValue in
            if viewSize == .zero { lastProgress = progress }
            viewSize = newValue
        }
    }
    
    /// Line Scrubber Configs
    struct Config {
        var trackHeight: CGFloat = 8
        var activeTint: Color = .black
        var inActiveTint: Color = .gray.opacity(0.3)
    }
}

#Preview {
    @Previewable @State var progress: TimeInterval = 0
    
    LineScrubber(current: $progress, total: 15)
}
