//
//  HandOverlayView.swift - Optimized with Reduced Jitter
//

import SwiftUI

struct HandOverlayView: View {
    let hands: [TrackedHand]
    @State private var animationPhase: Double = 0
    
    var body: some View {
        ZStack {
            ForEach(Array(hands.enumerated()), id: \.element.id) { index, hand in
                ZStack {
                    // Only show overlay if pinching - reduced animation complexity
                    if hand.isPinching {
                        // Simplified glow effect
                        Circle()
                            .fill(handColor(for: index).opacity(0.2))
                            .frame(width: 80, height: 80)
                            .blur(radius: 8)
                        
                        // Main circle with border - removed breathing animation
                        Circle()
                            .fill(handColor(for: index).opacity(0.15))
                            .frame(width: 60, height: 60)
                            .overlay(
                                Circle()
                                    .stroke(handColor(for: index), lineWidth: 3)
                                    .shadow(color: handColor(for: index).opacity(0.6), radius: 4)
                            )
                        
                        // Center dot
                        Circle()
                            .fill(handColor(for: index))
                            .frame(width: 8, height: 8)
                        
                        // Simplified status label
                        VStack(spacing: 2) {
                            Text(handLabel(for: index))
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("PINCH")
                                .font(.system(size: 7, weight: .bold))
                                .foregroundColor(.white)
                            
                            // Only show shake if significant
                            if hand.shakeIntensity > 15 {
                                Text("SHAKE")
                                    .font(.system(size: 6, weight: .bold))
                                    .foregroundColor(.yellow)
                            }
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(handColor(for: index).opacity(0.8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                )
                        )
                        .offset(y: -50)
                    } else {
                        // Minimal indicator when not pinching
                        Circle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 16, height: 16)
                            .overlay(
                                Circle()
                                    .stroke(Color.gray.opacity(0.6), lineWidth: 1)
                            )
                        
                        Text(handLabel(for: index))
                            .font(.system(size: 7, weight: .medium))
                            .foregroundColor(.gray)
                            .padding(.horizontal, 3)
                            .padding(.vertical, 1)
                            .background(
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color.gray.opacity(0.4))
                            )
                            .offset(y: -20)
                    }
                }
                .position(hand.position)
                // Reduced animation duration and easing for smoother movement
                .animation(.easeOut(duration: 0.1), value: hand.position)
                .animation(.easeInOut(duration: 0.2), value: hand.isPinching)
            }
            
            // Simplified connection line - only show if both hands are actively pinching
            if hands.count == 2 &&
               hands.allSatisfy({ $0.isPinching && $0.shakeIntensity > 10 }) {
                Path { path in
                    path.move(to: hands[0].position)
                    path.addLine(to: hands[1].position)
                }
                .stroke(
                    LinearGradient(
                        colors: [handColor(for: 0).opacity(0.4), handColor(for: 1).opacity(0.4)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 2, dash: [8, 4])
                )
                .animation(.easeOut(duration: 0.1), value: hands.map { $0.position })
            }
        }
        // Removed breathing animation to reduce jitter
    }
    
    private func handColor(for index: Int) -> Color {
        switch index {
        case 0: return .blue
        case 1: return .green
        default: return .purple
        }
    }
    
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
        
        HandOverlayView(hands: [
            TrackedHand(position: CGPoint(x: 200, y: 300), confidence: 0.8, isPinching: true),
            TrackedHand(position: CGPoint(x: 600, y: 400), confidence: 0.9, isPinching: false)
        ])
    }
}
