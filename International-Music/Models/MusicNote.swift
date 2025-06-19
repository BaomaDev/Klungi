import SwiftUI

enum MusicNote: String, CaseIterable {
    case c4 = "C4"
    case d4 = "D4"
    case e4 = "E4"
    case f4 = "F4"
    case g4 = "G4"
    case a4 = "A4"
    case b4 = "B4"
    case c5 = "C5"
    
    var frequency: Float {
        switch self {
        case .c4: return 261.63
        case .d4: return 293.66
        case .e4: return 329.63
        case .f4: return 349.23
        case .g4: return 392.00
        case .a4: return 440.00
        case .b4: return 493.88
        case .c5: return 523.25
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
        case .c5: return .pink
        }
    }
}