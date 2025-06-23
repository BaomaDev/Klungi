// Enhanced SongManager.swift with background music integration

import SwiftUI
import AVFoundation
import Combine

class SongManager: ObservableObject {
    @Published var currentTime: Double = 0
    @Published var isPlaying: Bool = false
    @Published var score: Int = 0
    @Published var currentSong: Song?
    @Published var currentNote: SongNote?
    @Published var nextNote: SongNote?
    @Published var hitStreak: Int = 0
    @Published var missedNotes: Int = 0
    @Published var accuracy: Double = 0
    
    private var gameTimer: Timer?
    private var songStartTime: Date?
    private let noteHitWindow: Double = 0.5
    private var hitNotes: Set<UUID> = []
    private var requiredNotes: [SongNote] = []
    
    // Background music reference
    private var audioManager: AudioManager?
    
    // Scoring system
    private let perfectHitScore = 100
    private let goodHitScore = 50
    private let streakMultiplier = 2
    
    init() {}
    
    // Set audio manager reference
    func setAudioManager(_ audioManager: AudioManager) {
        self.audioManager = audioManager
    }
    
    // MARK: - Song Control Methods with Background Music
    func startSong(_ song: Song) {
        currentSong = song
        songStartTime = Date()
        currentTime = 0
        score = 0
        hitStreak = 0
        missedNotes = 0
        isPlaying = true
        hitNotes.removeAll()
        requiredNotes = song.noteSequence.filter { $0.isRequired }
        
        // Start background music if available
        if let backgroundMusic = song.backgroundMusicFileName {
            audioManager?.playBackgroundMusic(fileName: backgroundMusic, volume: song.backgroundMusicVolume)
        }
        
        // Start the game timer
        gameTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            self.updateGameState()
        }
        
        print("🎵 Started song: \(song.title) with \(requiredNotes.count) required notes")
    }
    
    func stopSong() {
        gameTimer?.invalidate()
        gameTimer = nil
        songStartTime = nil
        isPlaying = false
        currentTime = 0
        currentNote = nil
        nextNote = nil
        
        // Stop background music
        audioManager?.stopBackgroundMusic()
        
        print("🛑 Song stopped")
    }
    
    func pauseSong() {
        isPlaying = false
        gameTimer?.invalidate()
        gameTimer = nil
        
        // Pause background music
        audioManager?.pauseBackgroundMusic()
        
        print("⏸️ Song paused at time: \(currentTime)")
    }
    
    func resumeSong() {
        guard let song = currentSong, !isPlaying else { return }
        
        isPlaying = true
        songStartTime = Date().addingTimeInterval(-currentTime)
        
        // Resume background music
        audioManager?.resumeBackgroundMusic()
        
        gameTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            self.updateGameState()
        }
        
        print("▶️ Song resumed at time: \(currentTime)")
    }
    
    // MARK: - Background Music Volume Control
    func adjustBackgroundMusicVolume(for gameEvent: GameEvent) {
        guard let audioManager = audioManager else { return }
        
        switch gameEvent {
        case .noteHit:
            // Briefly lower background music when note is hit
            audioManager.fadeBackgroundMusic(to: audioManager.backgroundMusicVolume * 0.7, duration: 0.1)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                audioManager.fadeBackgroundMusic(to: audioManager.backgroundMusicVolume, duration: 0.2)
            }
        case .streak(let count):
            if count >= 10 {
                // Increase background volume during streak
                audioManager.fadeBackgroundMusic(to: min(1.0, audioManager.backgroundMusicVolume * 1.2), duration: 0.5)
            }
        case .streakBroken:
            // Return to normal volume
            if let song = currentSong {
                audioManager.fadeBackgroundMusic(to: song.backgroundMusicVolume, duration: 1.0)
            }
        }
    }
    
    // MARK: - Game State Updates (existing code with enhancements)
    private func updateGameState() {
        guard let startTime = songStartTime,
              let song = currentSong,
              isPlaying else { return }
        
        currentTime = Date().timeIntervalSince(startTime)
        
        if currentTime >= song.duration {
            finishSong()
            return
        }
        
        updateCurrentNotes()
        checkMissedNotes()
        updateAccuracy()
    }
    
    private func updateCurrentNotes() {
        guard let song = currentSong else { return }
        
        currentNote = song.noteSequence.first { note in
            currentTime >= (note.startTime - noteHitWindow) &&
            currentTime <= (note.endTime + noteHitWindow)
        }
        
        nextNote = song.noteSequence.first { note in
            note.startTime > currentTime
        }
    }
    
    private func checkMissedNotes() {
        guard let song = currentSong else { return }
        
        for note in requiredNotes {
            if !hitNotes.contains(note.id) &&
               currentTime > (note.endTime + noteHitWindow) {
                
                hitNotes.insert(note.id)
                missedNotes += 1
                hitStreak = 0
                
                // Trigger background music adjustment
                adjustBackgroundMusicVolume(for: .streakBroken)
                
                print("❌ Missed note: \(note.note.rawValue) at time \(note.startTime)")
            }
        }
    }
    
    private func updateAccuracy() {
        guard !requiredNotes.isEmpty else {
            accuracy = 0
            return
        }
        
        let totalProcessedNotes = hitNotes.count
        let correctHits = totalProcessedNotes - missedNotes
        
        if totalProcessedNotes > 0 {
            accuracy = Double(correctHits) / Double(totalProcessedNotes) * 100
        } else {
            accuracy = 0
        }
    }
    
    // MARK: - Note Hit Detection (enhanced)
    func hitNote(_ note: MusicNote) {
        guard let currentNote = currentNote,
              currentNote.note == note,
              !hitNotes.contains(currentNote.id),
              isPlaying else {
            return
        }
        
        let targetTime = (currentNote.startTime + currentNote.endTime) / 2
        let timingDifference = abs(currentTime - targetTime)
        let hitAccuracy = max(0, 1 - (timingDifference / noteHitWindow))
        
        hitNotes.insert(currentNote.id)
        
        var noteScore: Int
        if hitAccuracy >= 0.8 {
            noteScore = perfectHitScore
            hitStreak += 1
            print("🎯 Perfect hit!")
        } else if hitAccuracy >= 0.5 {
            noteScore = goodHitScore
            hitStreak += 1
            print("👍 Good hit!")
        } else {
            noteScore = goodHitScore / 2
            hitStreak = max(0, hitStreak - 1)
            print("👌 Okay hit!")
        }
        
        if hitStreak >= 5 {
            noteScore *= streakMultiplier
            adjustBackgroundMusicVolume(for: .streak(hitStreak))
            print("🔥 Streak bonus! x\(streakMultiplier)")
        }
        
        // Trigger background music adjustment for note hit
        adjustBackgroundMusicVolume(for: .noteHit)
        
        score += noteScore
        
        print("🎵 Hit note: \(note.rawValue) - Score: +\(noteScore) (Total: \(score)) - Streak: \(hitStreak)")
    }
    
    // MARK: - Song Completion
    private func finishSong() {
        stopSong()
        
        let finalAccuracy = accuracy
        let totalHits = hitNotes.count - missedNotes
        let totalRequired = requiredNotes.count
        
        print("🏁 Song completed!")
        print("📊 Final Score: \(score)")
        print("🎯 Accuracy: \(String(format: "%.1f", finalAccuracy))%")
        print("🎵 Notes Hit: \(totalHits)/\(totalRequired)")
        print("🔥 Best Streak: \(hitStreak)")
    }
    
    // MARK: - Utility Methods (existing code)
    var progress: Double {
        guard let song = currentSong else { return 0 }
        return min(currentTime / song.duration, 1.0)
    }
    
    var timeRemaining: Double {
        guard let song = currentSong else { return 0 }
        return max(song.duration - currentTime, 0)
    }
    
    var formattedCurrentTime: String {
        let minutes = Int(currentTime) / 60
        let seconds = Int(currentTime) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var formattedTimeRemaining: String {
        let remaining = timeRemaining
        let minutes = Int(remaining) / 60
        let seconds = Int(remaining) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    func getGameStats() -> String {
        return """
        Song: \(currentSong?.title ?? "None")
        Time: \(formattedCurrentTime) / \(currentSong?.duration ?? 0)
        Score: \(score)
        Accuracy: \(String(format: "%.1f", accuracy))%
        Streak: \(hitStreak)
        Missed: \(missedNotes)
        Current Note: \(currentNote?.note.rawValue ?? "None")
        Next Note: \(nextNote?.note.rawValue ?? "None")
        Background Music: \(audioManager?.isBackgroundMusicPlaying == true ? "Playing" : "Stopped")
        """
    }
}

// MARK: - Game Events for Background Music Control
enum GameEvent {
    case noteHit
    case streak(Int)
    case streakBroken
}
