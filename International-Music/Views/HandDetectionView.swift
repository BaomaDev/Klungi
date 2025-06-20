//
//  HandDetectionView.swift - Horizontal Circle Layout
//

import SwiftUI

struct HandDetectionView: View {
    @EnvironmentObject var cameraManager: CameraManager
    @EnvironmentObject var audioManager: AudioManager
    @State private var circles: [MusicCircle] = []
    @State private var handPoints: [CGPoint] = []
    @State private var screenSize: CGSize = .zero
    @State private var orientation = UIDeviceOrientation.portrait
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                CameraPreviewView()
                    .onReceive(cameraManager.handPointsPublisher) { points in
                        handPoints = points
                        checkCollisions(in: geometry.size)
                    }
                
                ForEach(circles) { circle in
                    MusicCircleView(circle: circle)
                        .position(circle.position)
                }
                
                HandOverlayView(handPoints: handPoints)
                
                VStack {
                    HStack {
                        StatusIndicatorView(handCount: handPoints.count)
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
    
    // MARK: - Horizontal Circle Layout
    private func setupHorizontalCircles(for size: CGSize = UIScreen.main.bounds.size) {
        let notes = MusicNote.allCases
        let screenWidth = size.width
        let screenHeight = size.height
        
        // Calculate spacing for horizontal layout
        let totalNotes = notes.count // 7 notes
        let circleRadius: CGFloat = 45.0
        let minSpacing: CGFloat = circleRadius * 2.2 // Minimum space between circles
                
        // Check if we need to adjust for screen width
        let availableWidth = screenWidth - 100 // 50px margin on each side
        let spacing = min(minSpacing, availableWidth / CGFloat(totalNotes - 1))
        
        // Calculate starting position to center the layout
        let actualTotalWidth = CGFloat(totalNotes - 1) * spacing
        let startX = (screenWidth - actualTotalWidth) / 2
        
        // Position all circles horizontally at the same Y level
        let centerY = screenHeight * 0.3 // Position at 60% from top
        
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
    
    // Enhanced collision detection with better precision
    private func checkCollisions(in size: CGSize) {
        let currentTime = CACurrentMediaTime()
        
        for handPoint in handPoints {
            for index in circles.indices {
                let circle = circles[index]
                let distance = sqrt(pow(handPoint.x - circle.position.x, 2) + pow(handPoint.y - circle.position.y, 2))
                
                // Slightly larger collision radius for better interaction
                let collisionRadius = circle.radius * 1.1
                
                if distance <= collisionRadius && currentTime - circle.lastTriggerTime > 0.25 {
                    circles[index].isActive = true
                    circles[index].lastTriggerTime = currentTime
                    
                    audioManager.playNote(circle.note)
                    
                    // Reset active state after animation
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        if index < circles.count {
                            circles[index].isActive = false
                        }
                    }
                }
            }
        }
    }
}
