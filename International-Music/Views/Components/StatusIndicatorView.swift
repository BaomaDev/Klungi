import SwiftUI

struct StatusIndicatorView: View {
    let handCount: Int
    
    var body: some View {
        HStack {
            Image(systemName: "hand.raised.fill")
                .foregroundColor(statusColor)
            
            Text(statusText)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(statusColor.opacity(0.9))
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.8), lineWidth: 1.5)
        )
    }
    
    private var statusColor: Color {
        handCount >= 2 ? .green : handCount == 1 ? .blue : .gray
    }
    
    private var statusText: String {
        handCount >= 2 ? "Both Hands" : handCount == 1 ? "One Hand" : "No Hands"
    }
}

#Preview {
    StatusIndicatorView(handCount: 1)
}