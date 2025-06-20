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
    var radius: CGFloat = 50.0
    var isActive: Bool = false
    var lastTriggerTime: TimeInterval = 0
    let note: MusicNote
    
}
