import SwiftUI

struct MusicCircleView: View {
    let circle: MusicCircle
    
    var body: some View {
        ZStack {
            Circle()
                .fill(circle.note.color.opacity(circle.isActive ? 0.4 : 0.2))
                .frame(width: circle.radius * 2, height: circle.radius * 2)
                .scaleEffect(circle.isActive ? 1.3 : 1.0)
                .animation(.easeInOut(duration: 0.3), value: circle.isActive)
            
            Circle()
                .stroke(circle.note.color, lineWidth: circle.isActive ? 6 : 3)
                .frame(width: circle.radius * 2, height: circle.radius * 2)
                .scaleEffect(circle.isActive ? 1.3 : 1.0)
                .animation(.easeInOut(duration: 0.3), value: circle.isActive)
            
            if circle.isActive {
                Circle()
                    .stroke(circle.note.color.opacity(0.3), lineWidth: 2)
                    .frame(width: circle.radius * 3, height: circle.radius * 3)
                    .opacity(0.5)
                    .animation(.easeOut(duration: 0.6), value: circle.isActive)
            }
            
            Text(circle.note.rawValue)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .padding(4)
                .background(Color.black.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 4))
        }
    }
}

#Preview {
    MusicCircleView(circle: MusicCircle(position: CGPoint(x: 100, y: 100), note: .c4))
}