//
//  Formatter.swift
//  VoiceNotes
//
//  Created by Ziqa on 16/02/26.
//

import Foundation

/// Format date into string, use "dd MMM yyy" for the "format" value
func format(date: Date, format: String) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = format
    return formatter.string(from: date)
}

/// Format time into string to have minutes and seconds
func format(time: TimeInterval) -> String {
    let minutes = Int(time) / 60
    let seconds = Int(time) % 60
    return String(format: "%1d.%02d", minutes, seconds)
}
