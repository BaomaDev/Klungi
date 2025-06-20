//
//  MusicNote.swift
//  International-Music
//
//  Created by Jesse Robinson Junior Simanjuntak on 17/06/25.
//

import SwiftUI

enum MusicNote: String, CaseIterable {
    case c4 = "C4"
    case d4 = "D4"
    case e4 = "E4"
    case f4 = "F4"
    case g4 = "G4"
    case a4 = "A4"
    case b4 = "B4"
    case b5 = "B5"
    case b6 = "B6"
    
    var frequency: Float {
        switch self {
        case .c4: return 261.63
        case .d4: return 293.66
        case .e4: return 329.63
        case .f4: return 349.23
        case .g4: return 392.00
        case .a4: return 440.00
        case .b4: return 493.88
        case .b5: return 523.25
        case .b6: return 587.33
        }
    }
    
    var color: Color {
        switch self {
        case .c4: return .red
        case .d4: return .orange
        case .e4: return .yellow
        case .f4: return .green
        case .g4: return .blue
        case .a4: return .indigo
        case .b4: return .purple
        case .b5: return .brown
        case .b6: return .gray
        }
    }
    
    // Image asset names
    var imageName: String {
        return "angklung1"
//        switch self {
//        case .c4: return "angklung1"
//        case .d4: return "angklung1"
//        case .e4: return "angklung1"
//        case .f4: return "angklung1"
//        case .g4: return "angklung1"
//        case .a4: return "angklung1"
//        case .b4: return "angklung1"
//        }
    }
    
    var systemImageName: String {
        return "music.note"
//        switch self {
//        case .c4: return "music.note"
//        case .d4: return "music.note"
//        case .e4: return "music.note"
//        case .f4: return "music.note"
//        case .g4: return "music.note"
//        case .a4: return "music.note"
//        case .b4: return "music.note"
//        }
    }
    
    // Custom image size multiplier for each note
    var imageSizeMultiplier: CGFloat {
        return 9.0
//        switch self {
//        case .c4: return 1.0    // Smaller
//        case .d4: return 1.0    // Medium-small
//        case .e4: return 1.0    // Standard
//        case .f4: return 1.0   // Medium-large
//        case .g4: return 1.0   // Large
//        case .a4: return 1.0   // Very large
//        case .b4: return 1.0  // Largest
//        }
    }
    
    // Alternative: Fixed sizes (if you prefer absolute values)
//    var imageSize: CGSize {
//        switch self {
//        case .c4: return CGSize(width: 60, height: 60)
//        case .d4: return CGSize(width: 70, height: 70)
//        case .e4: return CGSize(width: 80, height: 80)
//        case .f4: return CGSize(width: 90, height: 90)
//        case .g4: return CGSize(width: 100, height: 100)
//        case .a4: return CGSize(width: 110, height: 110)
//        case .b4: return CGSize(width: 120, height: 120)
//        }
//    }
}
