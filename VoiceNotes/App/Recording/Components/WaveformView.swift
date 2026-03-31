//
//  WaveformView.swift
//  VoiceNotes
//
//  Created by Ziqa on 31/03/26.
//

import SwiftUI

struct WaveformView: View {
    var samples: [Float]
    var isRecording: Bool
    
    private let barWidth: CGFloat = 2
    private let barGap: CGFloat = 2
    private var barStep: CGFloat { barWidth + barGap }
    
    // Shortest visible bar height
    private let minBarHeight: CGFloat = 3
    
    // Max barheight ratio from view height
    private let maxBarHeightRatio: CGFloat = 0.6
    
    var dotRadius: CGFloat = 5
    
    // Drag scroll state
    @State private var dragOffset: CGFloat = 0
    @State private var lastDragOffset: CGFloat = 0
    
    // When recording, auto-follow the newest sample
    // When dragging, freeze the view at the drag position
    @State private var isDragging = false
    
    var body: some View {
        GeometryReader { geo in
            Canvas { ctx, size in
                drawBars(ctx: ctx, size: size)
                drawPlayhead(ctx: ctx, size: size)
            }
            .contentShape(.rect)
            .gesture(scrubGesture)
            .onChange(of: isRecording) { oldValue, newValue in
                if newValue == true {
                    dragOffset = 0
                    lastDragOffset = 0
                }
            }
        }
    }
    
    func drawBars(ctx: GraphicsContext, size: CGSize) {
        let centerX = size.width / 2
        let centerY = size.height / 2
        let maxHeight = size.height * maxBarHeightRatio
        
        for (i, sample) in samples.reversed().enumerated() {
            let barX: CGFloat
            
            if isRecording {
                barX = centerX - CGFloat(i + 1) * barStep
            } else {
                barX = centerX - CGFloat(i + 1) * barStep + dragOffset
            }
            
            guard barX >= -barWidth && barX <= size.width + barWidth else { continue }

            let barH = max(minBarHeight, CGFloat(sample) * maxHeight)
            let rect = CGRect(
                x: barX - barWidth / 2,
                y: centerY - barH / 2,
                width: barWidth,
                height: barH
            )
            
            ctx.fill(
                Path(roundedRect: rect, cornerRadius: barWidth / 2),
                with: .color(.red)
            )
        }
    }
    
    func drawPlayhead(ctx: GraphicsContext, size: CGSize) {
        let centerX = size.width / 2
        let topY = dotRadius * 2 + 2
        let bottomY = size.height - dotRadius * 2 - 2
        
        var linePath = Path()
        linePath.move(to: CGPoint(x: centerX, y: topY))
        linePath.addLine(to: CGPoint(x: centerX, y: bottomY))
        ctx.stroke(linePath, with: .color(.yellow), lineWidth: 1.5)
        
        ctx.fill(
            Path(
                ellipseIn: CGRect(
                    x: centerX - dotRadius,
                    y: 2,
                    width: dotRadius * 2,
                    height: dotRadius * 2
                )
            ),
            with: .color(.yellow)
        )
        
        ctx.fill(
            Path(
                ellipseIn: CGRect(
                    x: centerX - dotRadius,
                    y: size.height - 2 - dotRadius * 2,
                    width: dotRadius * 2,
                    height: dotRadius * 2
                )
            ),
            with: .color(.yellow)
        )
    }
    
    private var scrubGesture: some Gesture {
        DragGesture(minimumDistance: 4)
            .onChanged { value in
                guard !isRecording else { return }
                dragOffset = clamped(lastDragOffset + value.translation.width)
            }
            .onEnded { _ in
                guard !isRecording else { return }
                lastDragOffset = dragOffset
            }
    }
    
    private func clamped(_ offset: CGFloat) -> CGFloat {
        let maxOffset = CGFloat(samples.count) * barStep
        return min(max(offset, 0), maxOffset)
    }
}

#Preview {
    //    WaveformView()
}
