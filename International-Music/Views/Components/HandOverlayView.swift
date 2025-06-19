import SwiftUI

struct HandOverlayView: View {
    let handPoints: [CGPoint]
    
    var body: some View {
        ZStack {
            ForEach(Array(handPoints.enumerated()), id: \.offset) { index, point in
                Circle()
                    .fill(handColor.opacity(0.15))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Circle()
                            .stroke(handColor, lineWidth: 3)
                            .shadow(color: handColor, radius: 8)
                    )
                    .overlay(
                        Circle()
                            .fill(handColor)
                            .frame(width: 6, height: 6)
                    )
                    .position(point)
                    .animation(.easeInOut(duration: 0.3), value: point)
            }
            
            if handPoints.count >= 2 {
                Path { path in
                    path.move(to: handPoints[0])
                    path.addLine(to: handPoints[1])
                }
                .stroke(handColor.opacity(0.4), style: StrokeStyle(lineWidth: 2, dash: [8, 4]))
            }
        }
    }
    
    private var handColor: Color {
        handPoints.count >= 2 ? .green : .blue
    }
}