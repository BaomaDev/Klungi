//
//  MenuView.swift
//  International-Music
//
//  Created by Jesse Robinson Junior Simanjuntak on 21/06/25.
//


//
//  MenuView.swift
//  International-Music
//
//  Created by Jesse Robinson Junior Simanjuntak on 21/06/25.
//

import SwiftUI

struct MenuView: View {
    @State private var selectedMode: GameMode? = nil
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color.black, Color.blue.opacity(0.3), Color.purple.opacity(0.2)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 40) {
                    // App Title
                    VStack(spacing: 10) {
                        Image(systemName: "music.note.house.fill")
                            .font(.system(size: 80))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .purple, .pink],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: .blue.opacity(0.5), radius: 10)
                        
                        Text("Hand Music")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.white, .blue.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        
                        Text("Play music with your hands")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 50)
                    
                    Spacer()
                    
                    // Menu Options
                    VStack(spacing: 20) {
                        // Practice Mode Button
                        NavigationLink(
                            destination: PracticeModeView(),
                            tag: .practice,
                            selection: $selectedMode
                        ) {
                            MenuButton(
                                title: "Practice Mode",
                                subtitle: "Free play with hand gestures",
                                icon: "hand.raised.fill",
                                gradientColors: [.blue, .cyan],
                                action: { selectedMode = .practice }
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Play a Song Button
                        NavigationLink(
                            destination: PlaySongView(),
                            tag: .playSong,
                            selection: $selectedMode
                        ) {
                            MenuButton(
                                title: "Play a Song",
                                subtitle: "Follow along with melodies",
                                icon: "music.note.list",
                                gradientColors: [.purple, .pink],
                                action: { selectedMode = .playSong }
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal, 30)
                    
                    Spacer()
                    
                    // Footer
                    VStack(spacing: 5) {
                        Text("Pinch and shake your hands to play notes")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        Text("Make sure to allow camera access")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary.opacity(0.7))
                    }
                    .padding(.bottom, 30)
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct MenuButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let gradientColors: [Color]
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 20) {
                // Icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: gradientColors.map { $0.opacity(0.3) },
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: gradientColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                
                // Text Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(subtitle)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Arrow
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 25)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.1),
                                Color.white.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    colors: gradientColors.map { $0.opacity(0.4) },
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
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