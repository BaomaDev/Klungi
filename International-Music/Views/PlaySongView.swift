//
//  PlaySongView.swift
//  International-Music
//
//  Created by Jesse Robinson Junior Simanjuntak on 21/06/25.
//


//
//  PlaySongView.swift
//  International-Music
//
//  Created by Jesse Robinson Junior Simanjuntak on 21/06/25.
//

import SwiftUI

struct PlaySongView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.black, Color.purple.opacity(0.3), Color.pink.opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Header with back button
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "house.fill")
                                .font(.system(size: 16, weight: .bold))
                            Text("Home")
                                .font(.system(size: 16, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(Color.black.opacity(0.6))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 25)
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                    
                    Spacer()
                    
                    Text("Play a Song")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                Spacer()
                
                // Coming Soon Content
                VStack(spacing: 20) {
                    Image(systemName: "music.note.list")
                        .font(.system(size: 80))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.purple, .pink, .blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: .purple.opacity(0.5), radius: 10)
                    
                    Text("Coming Soon!")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, .purple.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    Text("Song mode will let you follow along with popular melodies and learn new songs step by step")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    VStack(spacing: 12) {
                        FeatureRow(icon: "music.quarternote.3", text: "Follow along with melodies")
                        FeatureRow(icon: "chart.line.uptrend.xyaxis", text: "Track your progress")
                        FeatureRow(icon: "star.fill", text: "Unlock new songs")
                        FeatureRow(icon: "person.2.fill", text: "Multiplayer challenges")
                    }
                    .padding(.top, 20)
                }
                
                Spacer()
                
                // For now, redirect to practice mode
                Button(action: {
                    // We'll implement song selection later
                    presentationMode.wrappedValue.dismiss()
                }) {
                    HStack {
                        Image(systemName: "hand.raised.fill")
                            .font(.system(size: 18, weight: .bold))
                        Text("Try Practice Mode Instead")
                            .font(.system(size: 18, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 15)
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(
                                LinearGradient(
                                    colors: [.purple, .pink],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                }
                .padding(.bottom, 40)
            }
        }
        .navigationBarHidden(true)
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.purple)
                .frame(width: 20)
            
            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding(.horizontal, 40)
    }
}

#Preview {
    PlaySongView()
}
