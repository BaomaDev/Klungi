//
//  PlaySongView.swift
//  International-Music
//
//  Created by Jesse Robinson Junior Simanjuntak on 21/06/25.
//

import SwiftUI

struct PlaySongView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var cameraManager = CameraManager()
    @StateObject private var audioManager = AudioManager()
    @StateObject private var songManager = SongManager()
    
    // Song selection state
    @State private var showSongSelection = true
    @State private var selectedSong: Song?
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if showSongSelection {
                SongSelectionView(
                    onSongSelected: { song in
                        selectedSong = song
                        showSongSelection = false
                        cameraManager.requestPermission()
                    },
                    onBack: {
                        presentationMode.wrappedValue.dismiss()
                    }
                )
            } else if let song = selectedSong {
                SongGameplayView(
                    song: song,
                    cameraManager: cameraManager,
                    audioManager: audioManager,
                    songManager: songManager,
                    onBack: {
                        showSongSelection = true
                        selectedSong = nil
                        songManager.stopSong()
                        cameraManager.stopSession()
                    }
                )
            }
        }
        .navigationBarHidden(true)
    }
}

// MARK: - Song Selection View
struct SongSelectionView: View {
    let onSongSelected: (Song) -> Void
    let onBack: () -> Void
    
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
                // Header
                HStack {
                    Button(action: onBack) {
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
                    
                    Text("Choose a Song")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                // Song List
                ScrollView {
                    LazyVStack(spacing: 20) {
                        ForEach(Song.demoSongs) { song in
                            SongCard(song: song) {
                                onSongSelected(song)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                
                Spacer()
            }
        }
    }
}

// MARK: - Song Card
struct SongCard: View {
    let song: Song
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(song.title)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text(song.artist)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 4) {
                        Image(systemName: "music.note")
                            .font(.system(size: 24))
                            .foregroundColor(.purple)
                        
                        Text("\(song.bpm) BPM")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                
                // Song info
                HStack {
                    Label("\(Int(song.duration))s", systemImage: "clock")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        ForEach(song.backgroundColors.prefix(3), id: \.self) { color in
                            Circle()
                                .fill(color)
                                .frame(width: 12, height: 12)
                        }
                    }
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: song.backgroundColors.map { $0.opacity(0.2) },
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Song Gameplay View
struct SongGameplayView: View {
    let song: Song
    let cameraManager: CameraManager
    let audioManager: AudioManager
    let songManager: SongManager
    let onBack: () -> Void
    
    @State private var currentLyric: LyricLine?
    @State private var nextLyric: LyricLine?
    @State private var gameStarted = false
    @State private var showCountdown = false
    @State private var countdownValue = 3
    
    var body: some View {
        ZStack {
            // Dynamic background
            LinearGradient(
                colors: song.backgroundColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .opacity(0.3)
            
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            if cameraManager.isAuthorized && gameStarted {
                // Game content
                SongHandDetectionView(
                    song: song,
                    songManager: songManager,
                    currentLyric: currentLyric
                )
                .environmentObject(cameraManager)
                .environmentObject(audioManager)
                
            } else if showCountdown {
                // Countdown overlay
                CountdownView(value: countdownValue)
                
            } else {
                // Start screen
                SongStartScreen(
                    song: song,
                    onStart: startGame,
                    onBack: onBack
                )
            }
            
            // Always show back button
            VStack {
                HStack {
                    Button(action: onBack) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.left")
                                .font(.system(size: 16, weight: .bold))
                            Text("Back")
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
                    
                    if gameStarted {
                        // Song progress
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("\(song.title)")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("Score: \(songManager.score)")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                Spacer()
            }
        }
        .onReceive(songManager.$currentTime) { time in
            updateLyrics(for: time)
        }
        .onAppear {
            if !cameraManager.isAuthorized {
                cameraManager.requestPermission()
            }
            
            songManager.setAudioManager(audioManager)
        }
    }
    
    private func startGame() {
        showCountdown = true
        countdownValue = 3
        
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            countdownValue -= 1
            
            if countdownValue <= 0 {
                timer.invalidate()
                showCountdown = false
                gameStarted = true
                cameraManager.startSession()
                songManager.startSong(song)
            }
        }
    }
    
    private func updateLyrics(for time: Double) {
        // Find current lyric
        currentLyric = song.lyrics.first { lyric in
            time >= lyric.startTime && time <= lyric.endTime
        }
        
        // Find next lyric
        nextLyric = song.lyrics.first { lyric in
            lyric.startTime > time
        }
    }
}

// MARK: - Song Start Screen
struct SongStartScreen: View {
    let song: Song
    let onStart: () -> Void
    let onBack: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Song info
            VStack(spacing: 16) {
                Text(song.title)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text(song.artist)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.secondary)
                
                HStack(spacing: 20) {
                    Label("\(Int(song.duration))s", systemImage: "clock")
                    Label("\(song.bpm) BPM", systemImage: "metronome")
                    Label("\(song.noteSequence.count) notes", systemImage: "music.note")
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
            }
            
            // Instructions
            VStack(spacing: 12) {
                Text("How to Play:")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                
                VStack(spacing: 8) {
                    InstructionRow(icon: "hand.raised.fill", text: "Use pinch gestures to play notes")
                    InstructionRow(icon: "waveform", text: "Shake your hand while pinching")
                    InstructionRow(icon: "music.note", text: "Hit the right notes at the right time")
                    InstructionRow(icon: "star.fill", text: "Follow the lyrics and melody")
                }
            }
            
            Spacer()
            
            // Start button
            Button(action: onStart) {
                HStack {
                    Image(systemName: "play.fill")
                        .font(.system(size: 20, weight: .bold))
                    Text("Start Playing")
                        .font(.system(size: 20, weight: .bold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 40)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 30)
                        .fill(
                            LinearGradient(
                                colors: song.backgroundColors,
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
            }
            .padding(.bottom, 40)
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Instruction Row
struct InstructionRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.purple)
                .frame(width: 20)
            
            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
            
            Spacer()
        }
    }
}

// MARK: - Countdown View
struct CountdownView: View {
    let value: Int
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text(value > 0 ? "\(value)" : "Go!")
                    .font(.system(size: 80, weight: .bold))
                    .foregroundColor(.white)
                    .scaleEffect(value <= 0 ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 0.3), value: value)
                
                Text("Get ready to play!")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    PlaySongView()
}
