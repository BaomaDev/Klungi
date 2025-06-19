//
//  HandOverlayView.swift
//  International-Music
//
//  Created by Jesse Robinson Junior Simanjuntak on 17/06/25.
//

import SwiftUI

struct HandOverlayView: View {
    let handPoints: [CGPoint]
    @State private var animationPhase: Double = 0
    
    var body: some View {
        ZStack {
            ForEach(Array(handPoints.enumerated()), id: \.offset) { index, point in
                ZStack {
                    // Outer breathing glow
                    Circle()
                        .fill(handColor(for: index).opacity(0.1))
                        .frame(width: 100 + sin(animationPhase + Double(index) * 0.5) * 10,
                               height: 100 + sin(animationPhase + Double(index) * 0.5) * 10)
                        .blur(radius: 15)
                    
                    // Middle glow circle
                    Circle()
                        .fill(handColor(for: index).opacity(0.2))
                        .frame(width: 80, height: 80)
                        .blur(radius: 8)
                    
                    // Main circle with stable border
                    Circle()
                        .fill(handColor(for: index).opacity(0.15))
                        .frame(width: 60, height: 60)
                        .overlay(
                            Circle()
                                .stroke(handColor(for: index), lineWidth: 3)
                                .shadow(color: handColor(for: index).opacity(0.8), radius: 6)
                        )
                    
                    // Center dot
                    Circle()
                        .fill(handColor(for: index))
                        .frame(width: 8, height: 8)
                    
                    // Stable hand label - uses consistent left/right identification
                    Text(handLabel(for: index))
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(handColor(for: index).opacity(0.9))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                )
                        )
                        .offset(y: -45)
                }
                .position(point)
                .animation(.easeOut(duration: 0.15), value: point)
            }
            
            // Connection line between hands (only if we have exactly 2 hands)
            if handPoints.count == 2 {
                Path { path in
                    path.move(to: handPoints[0])
                    path.addLine(to: handPoints[1])
                }
                .stroke(
                    LinearGradient(
                        colors: [handColor(for: 0).opacity(0.4), handColor(for: 1).opacity(0.4)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 2, dash: [10, 5])
                )
                .animation(.easeOut(duration: 0.15), value: handPoints)
            }
        }
        .onAppear {
            // Start breathing animation
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                animationPhase = .pi * 2
            }
        }
    }
    
    // Consistent color assignment based on position index
    private func handColor(for index: Int) -> Color {
        switch index {
        case 0: return .blue      // First hand (typically left)
        case 1: return .green     // Second hand (typically right)
        default: return .purple   // Additional hands (shouldn't happen with max 2)
        }
    }
    
    // Consistent label based on index (since hands are sorted left-to-right)
    private func handLabel(for index: Int) -> String {
        switch index {
        case 0: return "LEFT"
        case 1: return "RIGHT"
        default: return "HAND \(index + 1)"
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        
        HandOverlayView(handPoints: [
            CGPoint(x: 200, y: 300),
            CGPoint(x: 600, y: 400)
        ])
    }
}
