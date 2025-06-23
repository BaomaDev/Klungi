import SwiftUI

struct MenuView: View {
    @State private var selectedMode: GameMode? = nil

    var body: some View {
        NavigationView {
            ZStack {
                Color.white.ignoresSafeArea()

                VStack(spacing: 40) {
                    VStack(spacing: 10) {
                        Image(systemName: "music.note.house.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.blue)

                        Text("Hand Music")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.black)

                        Text("Play music with your hands")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 50)

                    Spacer()

                    VStack(spacing: 20) {
                        NavigationLink(
                            destination: PracticeModeView(),
                            tag: .practice,
                            selection: $selectedMode
                        ) {
                            MenuButtonSimple(
                                title: "Practice Mode",
                                subtitle: "Free play with hand gestures",
                                icon: "hand.raised.fill",
                                backgroundColor: .blue,
                                action: { selectedMode = .practice }
                            )
                        }

                        NavigationLink(
                            destination: PlaySongView(),
                            tag: .playSong,
                            selection: $selectedMode
                        ) {
                            MenuButtonSimple(
                                title: "Play a Song",
                                subtitle: "Follow along with melodies",
                                icon: "music.note.list",
                                backgroundColor: .purple,
                                action: { selectedMode = .playSong }
                            )
                        }
                    }
                    .padding(.horizontal, 30)

                    Spacer()

                    VStack(spacing: 5) {
                        Text("Pinch and shake your hands to play notes")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)

                        Text("Make sure to allow camera access")
                            .font(.system(size: 12))
                            .foregroundColor(.gray.opacity(0.7))
                    }
                    .padding(.bottom, 30)
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct MenuButtonSimple: View {
    let title: String
    let subtitle: String
    let icon: String
    let backgroundColor: Color
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 20) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .background(backgroundColor)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.black)

                    Text(subtitle)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(16)
        }
        .scaleEffect(isPressed ? 0.96 : 1.0)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

enum GameMode: CaseIterable {
    case practice
    case playSong
}

#Preview {
    MenuView()
}
