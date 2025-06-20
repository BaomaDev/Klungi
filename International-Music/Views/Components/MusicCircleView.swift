//
//  MusicCircleView.swift
//  International-Music
//
//  Created by Jesse Robinson Junior Simanjuntak on 17/06/25.
//

import SwiftUI

struct MusicCircleView: View {
    let circle: MusicCircle
    @State private var shakeOffset: CGFloat = 0
    @State private var rotationAngle: Double = 0
    @State private var scaleEffect: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            // Background glow effect when active - LOWER OPACITY
            if circle.isActive {
                imageView
                    .frame(width: imageWidth * 1.5, height: imageHeight * 1.5)
                    .opacity(0.3) // Changed from 1.0 to 0.3 for lower opacity
                    .blur(radius: 10)
                    .scaleEffect(1.5)
                    .animation(.easeOut(duration: 0.6), value: circle.isActive)
            }
            
            // Main image with shake and pulse effects - 100% OPACITY
            imageView
                .frame(width: imageWidth, height: imageHeight)
                .scaleEffect(scaleEffect)
                .rotationEffect(.degrees(rotationAngle))
                .offset(x: shakeOffset, y: shakeOffset * 0.5)
                .opacity(1.0) // Always 100% opacity for main image
            
            // Note label overlay
            ZStack {
                Spacer()
                Text(circle.note.rawValue)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(circle.note.color.opacity(0.8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                    )
                    .offset(y: max(imageHeight, imageWidth) / 2 + 15)
                    .scaleEffect(circle.isActive ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.3), value: circle.isActive)
            }
        }
        .onChange(of: circle.isActive) { isActive in
            if isActive {
                startShakeAnimation()
            }
        }
    }
    
    // Computed properties for image dimensions
    private var imageWidth: CGFloat {
        // Option 1: Use multiplier based on circle radius
        return circle.radius * circle.note.imageSizeMultiplier
        
        // Option 2: Use fixed size (uncomment to use this instead)
        // return circle.note.imageSize.width
    }
    
    private var imageHeight: CGFloat {
        // Option 1: Use multiplier based on circle radius
        return circle.radius * circle.note.imageSizeMultiplier
        
        // Option 2: Use fixed size (uncomment to use this instead)
        // return circle.note.imageSize.height
    }
    
    @ViewBuilder
    private var imageView: some View {
        // Try to load custom image first, fallback to SF Symbol
        if UIImage(named: circle.note.imageName) != nil {
            // Custom image exists
            Image(circle.note.imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundColor(circle.note.color)
        } else {
            // Fallback to SF Symbol with colored background
            ZStack {
                Circle()
                    .fill(circle.note.color.opacity(0.3))
                    .overlay(
                        Circle()
                            .stroke(circle.note.color, lineWidth: 3)
                    )
                
                Image(systemName: circle.note.systemImageName)
                    .font(.system(size: min(imageWidth, imageHeight) * 0.3, weight: .bold))
                    .foregroundColor(circle.note.color)
            }
        }
    }
    
    private func startShakeAnimation() {
        // Shake animation - small vibration effect
        let shakeIntensity = min(imageWidth, imageHeight) * 0.05  // smaller for subtle vibration

        withAnimation(.easeInOut(duration: 0.05).repeatCount(10, autoreverses: true)) {
            shakeOffset = CGFloat.random(in: -shakeIntensity...shakeIntensity)
        }

        // Reset after the vibration ends
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeOut(duration: 0.1)) {
                shakeOffset = 0
            }
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        
        VStack(spacing: 30) {
            HStack(spacing: 30) {
                MusicCircleView(circle: MusicCircle(position: CGPoint(x: 100, y: 100), note: .c4))
                MusicCircleView(circle: MusicCircle(position: CGPoint(x: 200, y: 100), note: .d4))
            }
            
            HStack(spacing: 30) {
                MusicCircleView(circle: MusicCircle(position: CGPoint(x: 100, y: 200), radius: 60, note: .e4))
                MusicCircleView(circle: MusicCircle(position: CGPoint(x: 200, y: 200), radius: 60, note: .f4))
            }
            
            // Show all notes with different sizes
            HStack(spacing: 20) {
                ForEach(MusicNote.allCases, id: \.self) { note in
                    MusicCircleView(circle: MusicCircle(position: .zero, radius: 40, note: note))
                }
            }
        }
    }
}
