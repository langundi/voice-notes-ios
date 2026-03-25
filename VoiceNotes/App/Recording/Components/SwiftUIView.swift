//
//  SwiftUIView.swift
//  VoiceNotes
//
//  Created by Ziqa on 25/03/26.
//

import SwiftUI

struct SwiftUIView: View {
    var body: some View {
        VStack {
            Text("Title")
                .font(.title2)
                .fontWeight(.bold)
            
            HStack(alignment: .center, spacing: 8) {
                Text("\(formatDate(date: Date.now))")
                    .foregroundStyle(.secondary)
                    .fontWeight(.semibold)
                
                Text("\(formatTime(time: Date.now.timeIntervalSince1970))")
                    .foregroundStyle(.gray)
                    .monospacedDigit()
            }
            .frame(maxWidth: .infinity)
            
            Rectangle()
                .fill(.blue)
            
            Text("\(formatTimer(time: Date.now.timeIntervalSince1970))")
                .font(.largeTitle)
                .fontWeight(.bold)
                .monospacedDigit()
            
            HStack(spacing: 32) {
                Button {
                } label: {
                    Image(systemName: "15.arrow.trianglehead.counterclockwise")
                }
                
                Button {
                } label: {
                    Image(systemName: "play.fill")
                        .font(.largeTitle)
                        .contentTransition(.symbolEffect(.replace))
                }
                
                Button {
                } label: {
                    Image(systemName: "15.arrow.trianglehead.clockwise")
                }
            }
            .font(.title)
            .fontWeight(.medium)
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity)
        }
    }
}

#Preview {
    SwiftUIView()
}
