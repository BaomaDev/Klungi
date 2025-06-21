//
//  HandDetectionView.swift - Optimized with Jitter Reduction
//

import SwiftUI

struct HandDetectionView: View {
    @EnvironmentObject var cameraManager: CameraManager
    @EnvironmentObject var audioManager: AudioManager
    @State private var circles: [MusicCircle] = []
    @State private var hands: [TrackedHand] = []
    @State private var screenSize: CGSize = .zero
    @State private var orientation = UIDeviceOrientation.portrait
    
    // NEW: Collision detection optimization
    @State private var lastCollisionCheck: TimeInterval = 0
    private let collisionCheckInterval: TimeInterval = 1.0/30.0  // 30 FPS collision checking
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                CameraPreviewView()
                    .onReceive(cameraManager.handDataPublisher) { handData in
                        hands = handData
                        
                        // Throttle collision detection
                        let currentTime = CACurrentMediaTime()
                        if currentTime - lastCollisionCheck >= collisionCheckInterval {
                            checkCollisionsWithPinchAndShake(in: geometry.size)
                            lastCollisionCheck = currentTime
                        }
                    }
                
                ForEach(circles) { circle in
                    MusicCircleView(circle: circle)
                        .position(circle.position)
                }
                
                // Use smoothed positions for hand overlay
                HandOverlayView(hands: hands.map { hand in
                    var smoothedHand = hand
                    smoothedHand.position = hand.smoothedPosition
                    return smoothedHand
                })
                
                VStack {
                    HStack {
                        StatusIndicatorView(handCount: hands.count)
                        Spacer()
                    }
                    Spacer()
                }
                .padding()
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
    
    // MARK: - Circle Setup (unchanged)
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
    
    // MARK: - OPTIMIZED: Pinch + Shake Collision Logic
    private func checkCollisionsWithPinchAndShake(in size: CGSize) {
        let currentTime = CACurrentMediaTime()
        
        for hand in hands {
            // Use smoothed position for collision detection
            let handPosition = hand.smoothedPosition
            
            // More restrictive requirements for triggering
            guard hand.isPinching && hand.shakeIntensity > 10 else {
                continue
            }
            
            for index in circles.indices {
                let circle = circles[index]
                
                // Early exit if too soon since last trigger
                if currentTime - circle.lastTriggerTime < 0.5 {
                    continue
                }
                
                // Calculate distance using smoothed position
                let distance = sqrt(pow(handPosition.x - circle.position.x, 2) +
                                  pow(handPosition.y - circle.position.y, 2))
                
                // Check collision with standard radius
                let collisionRadius = circle.radius * 1.1  // Reduced from 1.2
                
                if distance <= collisionRadius {
                    // Activate circle and play sound
                    circles[index].isActive = true
                    circles[index].lastTriggerTime = currentTime
                    
                    // Play the note
                    audioManager.playNote(circle.note)
                    
                    print("🎵 Triggered: \(circle.note.rawValue) - Pinch: \(hand.isPinching), Shake: \(hand.shakeIntensity)")
                    
                    // Reset active state after animation
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
