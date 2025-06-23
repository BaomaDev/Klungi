//
//  SongHandDetectionView.swift - Updated to match Practice Mode interaction
//  International-Music
//
//  Created by Jesse Robinson Junior Simanjuntak on 23/06/25.
//

import SwiftUI

struct SongHandDetectionView: View {
    let song: Song
    let songManager: SongManager
    let currentLyric: LyricLine?
    
    @EnvironmentObject var cameraManager: CameraManager
    @EnvironmentObject var audioManager: AudioManager
    
    @State private var circles: [MusicCircle] = []
    @State private var hands: [TrackedHand] = []
    @State private var lastCollisionCheck: TimeInterval = 0
    @State private var screenSize: CGSize = .zero
    @State private var orientation = UIDeviceOrientation.portrait
    
    // Match practice mode collision detection - 30 FPS for better responsiveness
    private let collisionCheckInterval: TimeInterval = 1.0/30.0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Camera background
                CameraPreviewView()
                    .onReceive(cameraManager.handDataPublisher) { handData in
                        hands = handData
                        
                        // Throttle collision detection like practice mode
                        let currentTime = CACurrentMediaTime()
                        if currentTime - lastCollisionCheck >= collisionCheckInterval {
                            checkCollisionsWithPinchAndShake(in: geometry.size)
                            lastCollisionCheck = currentTime
                        }
                    }
                
                // Music circles - simplified rendering
                ForEach(circles) { circle in
                    SimpleMusicCircleView(
                        circle: circle,
                        isTarget: songManager.currentNote?.note == circle.note
                    )
                    .position(circle.position)
                }
                
                // Use smoothed positions for hand overlay like practice mode
                HandOverlayView(hands: hands.map { hand in
                    var smoothedHand = hand
                    smoothedHand.position = hand.smoothedPosition
                    return smoothedHand
                })
                
                // Minimal UI overlay
                VStack {
                    // Top bar
                    HStack {
                        // Simple progress
                        VStack(alignment: .leading) {
                            Text("Progress: \(songManager.formattedCurrentTime)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                            
                            ProgressView(value: songManager.progress)
                                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                                .frame(width: 200, height: 4)
                        }
                        
                        Spacer()
                        
                        // Simple score
                        VStack {
                            Text("\(songManager.score)")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                            Text("\(String(format: "%.0f", songManager.accuracy))%")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    .padding()
                    .background(Color.black.opacity(0.5))
                    
                    Spacer()
                    
                    // Bottom info
                    VStack(spacing: 12) {
                        // Current target note
                        if let currentNote = songManager.currentNote {
                            HStack {
                                Circle()
                                    .fill(currentNote.note.color)
                                    .frame(width: 24, height: 24)
                                    .overlay(
                                        Text(currentNote.note.rawValue)
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.white)
                                    )
                                
                                Text("Hit: \(currentNote.note.rawValue)")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            .padding()
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(12)
                        }
                        
                        // Simple lyrics
                        if let lyric = currentLyric {
                            Text(lyric.text)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .padding()
                                .background(Color.black.opacity(0.6))
                                .cornerRadius(12)
                        }
                    }
                    .padding()
                }
            }
            .onChange(of: geometry.size) { newSize in
                screenSize = newSize
                setupHorizontalCircles(for: newSize)
            }
            .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
                orientation = UIDevice.current.orientation
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    setupHorizontalCircles(for: screenSize)
                }
            }
        }
        .onAppear {
            cameraManager.startSession()
        }
        .onDisappear {
            cameraManager.stopSession()
        }
    }
    
    // MARK: - Circle Setup (matching practice mode)
    private func setupHorizontalCircles(for size: CGSize = UIScreen.main.bounds.size) {
        let notes = MusicNote.allCases
        let screenWidth = size.width
        let screenHeight = size.height
        
        let totalNotes = notes.count
        let circleRadius: CGFloat = 45.0
        let minSpacing: CGFloat = circleRadius * 2.2
                
        let availableWidth = screenWidth - 100
        let spacing = min(minSpacing, availableWidth / CGFloat(totalNotes - 1))
        
        let actualTotalWidth = CGFloat(totalNotes - 1) * spacing
        let startX = (screenWidth - actualTotalWidth) / 2
        
        let centerY = screenHeight * 0.3
        
        circles = notes.enumerated().map { index, note in
            let x = startX + CGFloat(index) * spacing
            let y = centerY
            
            return MusicCircle(
                position: CGPoint(x: x, y: y),
                radius: circleRadius,
                note: note
            )
        }
    }
    
    // MARK: - Enhanced Collision Detection (matching practice mode requirements)
    private func checkCollisionsWithPinchAndShake(in size: CGSize) {
        let currentTime = CACurrentMediaTime()
        
        for hand in hands {
            // Use smoothed position for collision detection like practice mode
            let handPosition = hand.smoothedPosition
            
            // More restrictive requirements matching practice mode: pinch + shake
            guard hand.isPinching && hand.shakeIntensity > 10 else {
                continue
            }
            
            for index in circles.indices {
                let circle = circles[index]
                
                // Prevent rapid triggers (matching practice mode timing)
                if currentTime - circle.lastTriggerTime < 0.5 {
                    continue
                }
                
                // Calculate distance using smoothed position
                let distance = sqrt(
                    pow(handPosition.x - circle.position.x, 2) +
                    pow(handPosition.y - circle.position.y, 2)
                )
                
                // Check collision with practice mode radius
                let collisionRadius = circle.radius * 1.1
                
                if distance <= collisionRadius {
                    // Activate circle
                    circles[index].isActive = true
                    circles[index].lastTriggerTime = currentTime
                    
                    // Send to song manager (KEEP GAME LOGIC)
                    songManager.hitNote(circle.note)
                    // Play audio through audio manager
                    audioManager.playNote(circle.note)
                    
                    print("🎵 Song Mode - Triggered: \(circle.note.rawValue) - Pinch: \(hand.isPinching), Shake: \(hand.shakeIntensity)")
                    
                    // Reset active state after animation (matching practice mode timing)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        if index < circles.count {
                            circles[index].isActive = false
                        }
                    }
                    
                    // Break to prevent multiple triggers from same hand
                    break
                }
            }
        }
    }
}

// MARK: - Simplified Supporting Views

struct SimpleMusicCircleView: View {
    let circle: MusicCircle
    let isTarget: Bool
    
    var body: some View {
        ZStack {
            // Simple glow for target
            if isTarget {
                Circle()
                    .fill(circle.note.color.opacity(0.3))
                    .frame(width: circle.radius * 2.5, height: circle.radius * 2.5)
                    .blur(radius: 10)
            }
            
            // Main circle
            MusicCircleView(circle: circle)
                .scaleEffect(isTarget ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 0.3), value: isTarget)
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        
        SongHandDetectionView(
            song: Song.demoSongs[0],
            songManager: SongManager(),
            currentLyric: nil
        )
        .environmentObject(CameraManager())
        .environmentObject(AudioManager())
    }
}
