//
//  HandDetectionView.swift
//  International-Music
//
//  Created by Jesse Robinson Junior Simanjuntak on 17/06/25.
//

import SwiftUI

struct HandDetectionView: View {
    @EnvironmentObject var cameraManager: CameraManager
    @EnvironmentObject var audioManager: AudioManager
    @State private var circles: [MusicCircle] = []
    @State private var handPoints: [CGPoint] = []
    
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
        }
        .onAppear {
            setupCircles()
            cameraManager.startSession()
        }
        .onDisappear {
            cameraManager.stopSession()
        }
    }
    
    // MARK: - Private Methods
    
    private func setupCircles() {
        // Circle setup logic...
        let notes = MusicNote.allCases
        let circleSpacing: CGFloat = 120
        let startY: CGFloat = 150
        let columns = 4
        
        for (index, note) in notes.enumerated() {
            let row = index / columns
            let col = index % columns
            
            let x = CGFloat(col) * circleSpacing + circleSpacing
            let y = startY + CGFloat(row) * circleSpacing
            
            let circle = InteractiveCircle(
                position: CGPoint(x: x, y: y),
                note: note
            )
            circles.append(circle)
        }
    }
    
    private func checkCollisions(in size: CGSize) {
        // Collision detection logic...
        let currentTime = CACurrentMediaTime()
        
        for handPoint in handPoints {
            for index in circles.indices {
                let circle = circles[index]
                let distance = sqrt(pow(handPoint.x - circle.position.x, 2) + pow(handPoint.y - circle.position.y, 2))
                
                if distance <= circle.radius {
                    // Check cooldown to prevent rapid triggering
                    if currentTime - circle.lastTriggerTime > triggerCooldown {
                        triggerCircle(at: index)
                        circles[index].lastTriggerTime = currentTime
                    }
                }
            }
        }
    }
}
