//
//  MusicCircle.swift
//  International-Music
//
//  Created by Jesse Robinson Junior Simanjuntak on 17/06/25.
//

import Foundation
import CoreGraphics

struct MusicCircle: Identifiable {
    let id = UUID()
    var position: CGPoint
    var radius: CGFloat
    var isActive: Bool = false
    var lastTriggerTime: TimeInterval = 0
    let note: MusicNote
    
    // Initialize with default radius
    init(position: CGPoint, note: MusicNote, radius: CGFloat = 50.0) {
        self.position = position
        self.note = note
        self.radius = radius
    }
}
