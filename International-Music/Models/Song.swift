//
//  Song.swift
//  International-Music
//
//  Created by Jesse Robinson Junior Simanjuntak on 23/06/25.
//


//
//  Song.swift
//  International-Music
//
//  Song model with lyrics and note sequences
//

import SwiftUI

struct Song: Identifiable {
    let id = UUID()
    let title: String
    let artist: String
    let lyrics: [LyricLine]
    let noteSequence: [SongNote]
    let bpm: Int
    let backgroundImageName: String
    let backgroundColors: [Color]
    
    let backgroundMusicFileName: String?  // Optional background music file
    let backgroundMusicVolume: Float      // Volume for background music (0.0 - 1.0)
    
    // Duration in seconds for the full song
    var duration: Double {
        return noteSequence.last?.endTime ?? 60.0
    }
}

struct LyricLine: Identifiable {
    let id = UUID()
    let text: String
    let startTime: Double  // Time in seconds when this line should appear
    let endTime: Double    // Time in seconds when this line should fade
    let isChorus: Bool
}

struct SongNote: Identifiable {
    let id = UUID()
    let note: MusicNote
    let startTime: Double  // Time in seconds when note should be played
    let endTime: Double    // Time in seconds when note should end
    let isRequired: Bool   // Whether player must hit this note
}

// MARK: - Sample Songs
extension Song {
    static let demoSongs: [Song] = [
        Song(
            title: "Morning Light",
            artist: "Original Composition",
            lyrics: [
                LyricLine(text: "Rasa Sayange", startTime: 0, endTime: 4, isChorus: false),
                LyricLine(text: "Golden rays shine so bright", startTime: 4, endTime: 8, isChorus: false),
                LyricLine(text: "Every day is a gift to see", startTime: 8, endTime: 12, isChorus: false),
                LyricLine(text: "All the beauty surrounding me", startTime: 12, endTime: 16, isChorus: false),
                
                LyricLine(text: "Sing along, sing along", startTime: 16, endTime: 20, isChorus: true),
                LyricLine(text: "Life is like a beautiful song", startTime: 20, endTime: 24, isChorus: true),
                LyricLine(text: "Sing along, sing along", startTime: 24, endTime: 28, isChorus: true),
                LyricLine(text: "Together we are strong", startTime: 28, endTime: 32, isChorus: true),
                
                LyricLine(text: "Through the clouds and stormy days", startTime: 32, endTime: 36, isChorus: false),
                LyricLine(text: "We will find our hopeful ways", startTime: 36, endTime: 40, isChorus: false),
                LyricLine(text: "Hand in hand we'll make it through", startTime: 40, endTime: 44, isChorus: false),
                LyricLine(text: "Dreams are meant for me and you", startTime: 44, endTime: 48, isChorus: false),
                
                LyricLine(text: "Sing along, sing along", startTime: 48, endTime: 52, isChorus: true),
                LyricLine(text: "Life is like a beautiful song", startTime: 52, endTime: 56, isChorus: true),
                LyricLine(text: "Sing along, sing along", startTime: 56, endTime: 60, isChorus: true),
                LyricLine(text: "Together we are strong", startTime: 60, endTime: 64, isChorus: true),
            ],
            noteSequence: [
                // First verse melody
                SongNote(note: .c4, startTime: 0, endTime: 1, isRequired: true),
                SongNote(note: .d4, startTime: 1, endTime: 2, isRequired: true),
                SongNote(note: .e4, startTime: 2, endTime: 4, isRequired: true),
                
                SongNote(note: .d4, startTime: 4, endTime: 5, isRequired: true),
                SongNote(note: .e4, startTime: 5, endTime: 6, isRequired: true),
                SongNote(note: .f4, startTime: 6, endTime: 8, isRequired: true),
                
                SongNote(note: .g4, startTime: 8, endTime: 9, isRequired: true),
                SongNote(note: .f4, startTime: 9, endTime: 10, isRequired: true),
                SongNote(note: .e4, startTime: 10, endTime: 12, isRequired: true),
                
                SongNote(note: .f4, startTime: 12, endTime: 13, isRequired: true),
                SongNote(note: .g4, startTime: 13, endTime: 14, isRequired: true),
                SongNote(note: .a4, startTime: 14, endTime: 16, isRequired: true),
                
                // Chorus melody (higher energy)
                SongNote(note: .a4, startTime: 16, endTime: 18, isRequired: true),
                SongNote(note: .g4, startTime: 18, endTime: 20, isRequired: true),
                
                SongNote(note: .f4, startTime: 20, endTime: 21, isRequired: true),
                SongNote(note: .g4, startTime: 21, endTime: 22, isRequired: true),
                SongNote(note: .a4, startTime: 22, endTime: 24, isRequired: true),
                
                SongNote(note: .a4, startTime: 24, endTime: 26, isRequired: true),
                SongNote(note: .g4, startTime: 26, endTime: 28, isRequired: true),
                
                SongNote(note: .f4, startTime: 28, endTime: 29, isRequired: true),
                SongNote(note: .e4, startTime: 29, endTime: 30, isRequired: true),
                SongNote(note: .d4, startTime: 30, endTime: 32, isRequired: true),
                
                // Second verse (similar to first)
                SongNote(note: .c4, startTime: 32, endTime: 33, isRequired: true),
                SongNote(note: .d4, startTime: 33, endTime: 34, isRequired: true),
                SongNote(note: .e4, startTime: 34, endTime: 36, isRequired: true),
                
                SongNote(note: .d4, startTime: 36, endTime: 37, isRequired: true),
                SongNote(note: .e4, startTime: 37, endTime: 38, isRequired: true),
                SongNote(note: .f4, startTime: 38, endTime: 40, isRequired: true),
                
                SongNote(note: .g4, startTime: 40, endTime: 41, isRequired: true),
                SongNote(note: .a4, startTime: 41, endTime: 42, isRequired: true),
                SongNote(note: .b4, startTime: 42, endTime: 44, isRequired: true),
                
                SongNote(note: .a4, startTime: 44, endTime: 45, isRequired: true),
                SongNote(note: .g4, startTime: 45, endTime: 46, isRequired: true),
                SongNote(note: .f4, startTime: 46, endTime: 48, isRequired: true),
                
                // Final chorus
                SongNote(note: .a4, startTime: 48, endTime: 50, isRequired: true),
                SongNote(note: .g4, startTime: 50, endTime: 52, isRequired: true),
                
                SongNote(note: .f4, startTime: 52, endTime: 53, isRequired: true),
                SongNote(note: .g4, startTime: 53, endTime: 54, isRequired: true),
                SongNote(note: .a4, startTime: 54, endTime: 56, isRequired: true),
                
                SongNote(note: .a4, startTime: 56, endTime: 58, isRequired: true),
                SongNote(note: .g4, startTime: 58, endTime: 60, isRequired: true),
                
                SongNote(note: .f4, startTime: 60, endTime: 61, isRequired: true),
                SongNote(note: .e4, startTime: 61, endTime: 62, isRequired: true),
                SongNote(note: .c4, startTime: 62, endTime: 64, isRequired: true),
            ],
            bpm: 120,
            backgroundImageName: "morning_background",
            backgroundColors: [.orange, .yellow, .pink],
            backgroundMusicFileName: "morning_light_background.mp3",  // ADD YOUR MUSIC FILE NAME HERE
            backgroundMusicVolume: 0.3  // Adjust volume (0.0 to 1.0)
        )
    ]
}
