//
//  Formatter.swift
//  VoiceNotes
//
//  Created by Ziqa on 16/02/26.
//

import Foundation

/// Format date into string, use "dd MMM yyy" for the "format" value
nonisolated func formatDate(date: Date) -> String {
    let formatter = DateFormatter()
    let calendar = Calendar.current
    let now = Date()
    
    if calendar.isDateInToday(date) {
        formatter.dateFormat = "HH:mm"
    } else if let daysAgo = calendar.dateComponents([.day], from: date, to: now).day, daysAgo < 3 {
        formatter.dateFormat = "EEEE"
    } else {
        formatter.dateFormat = "dd MMM yyyy"
    }
    
    return formatter.string(from: date)
}

/// Format time into string to have minutes and seconds
nonisolated func formatTime(time: TimeInterval) -> String {
    let minutes = Int(time) / 60
    let seconds = Int(time) % 60
    return String(format: "%1d.%02d", minutes, seconds)
}

/// Format timer
nonisolated func formatTimer(time: TimeInterval) -> String {
    let minutes = Int(time) / 60
    let seconds = Int(time) % 60
    let milliseconds = Int(time * 100) % 100
    return String(format: "%02d.%02d,%02d", minutes, seconds, milliseconds)
}

/// Get URL path
nonisolated func getURL(for fileName: String) -> URL {
    let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    let url = path.appending(path: fileName)
    return url
}

/// Get URL paths for multiple recordings
nonisolated func getURLs(for fileNames: [String]) -> [URL] {
    var url: [URL] = []
    for title in fileNames {
        let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        url.append(path.appending(path: title))
    }
    return url
}

/// Make unique URL path
nonisolated func makeUniqueURL(for title: String) -> URL {
    let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    var fileName = "\(title).m4a"
    var url = path.appending(path: fileName)
    var counter = 2
    
    // Checks if a file with the same name exists, adds a number to file name
    while FileManager.default.fileExists(atPath: url.path) {
        fileName = "\(title) \(counter).m4a"
        url = path.appending(path: fileName)
        counter += 1
    }
    
    return url
}
