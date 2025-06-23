//
//  AudioManager.swift
//  International-Music
//
//  Created by Jesse Robinson Junior Simanjuntak on 17/06/25.
//

import AVFoundation
import SwiftUI

class AudioManager: ObservableObject {
    private var audioPlayers: [String: AVAudioPlayer] = [:]
    private var backgroundMusicPlayer: AVAudioPlayer?
    
    @Published var isBackgroundMusicPlaying: Bool = false
    @Published var backgroundMusicVolume: Float = 0.5
    
    init() {
        setupAudioSession()
        preloadSounds()
    }
    
    // MARK: - Public Methods
    func playNote(_ note: MusicNote) {
        // Try to play local audio file first, fallback to generated tone
        if let player = audioPlayers[note.audioFileName] {
            player.stop()
            player.currentTime = 0
            player.play()
        } else {
            // Fallback to generated tone if audio file not found
            playGeneratedTone(frequency: note.frequency, duration: 0.5)
        }
    }
    
    // MARK: - Background Music Methods
    func playBackgroundMusic(fileName: String, volume: Float = 0.5) {
        stopBackgroundMusic() // Stop any currently playing background music
        
        guard let url = Bundle.main.url(forResource: fileName, withExtension: nil) ??
                       Bundle.main.url(forResource: fileName.replacingOccurrences(of: ".mp3", with: ""), withExtension: "mp3") ??
                       Bundle.main.url(forResource: fileName.replacingOccurrences(of: ".wav", with: ""), withExtension: "wav") ??
                       Bundle.main.url(forResource: fileName.replacingOccurrences(of: ".m4a", with: ""), withExtension: "m4a") else {
            print("Background music file not found: \(fileName)")
            return
        }
        
        do {
            backgroundMusicPlayer = try AVAudioPlayer(contentsOf: url)
            backgroundMusicPlayer?.numberOfLoops = -1  // Loop indefinitely
            backgroundMusicPlayer?.volume = volume
            backgroundMusicPlayer?.prepareToPlay()
            backgroundMusicPlayer?.play()
            
            isBackgroundMusicPlaying = true
            backgroundMusicVolume = volume
            
            print("🎵 Started background music: \(fileName)")
        } catch {
            print("Error playing background music \(fileName): \(error)")
        }
    }
    
    func stopBackgroundMusic() {
        backgroundMusicPlayer?.stop()
        backgroundMusicPlayer = nil
        isBackgroundMusicPlaying = false
        print("🛑 Stopped background music")
    }
    
    func pauseBackgroundMusic() {
        backgroundMusicPlayer?.pause()
        isBackgroundMusicPlaying = false
        print("⏸️ Paused background music")
    }
    
    func resumeBackgroundMusic() {
        backgroundMusicPlayer?.play()
        isBackgroundMusicPlaying = backgroundMusicPlayer?.isPlaying ?? false
        print("▶️ Resumed background music")
    }
    
    func setBackgroundMusicVolume(_ volume: Float) {
        backgroundMusicPlayer?.volume = volume
        backgroundMusicVolume = volume
    }
    
    func fadeBackgroundMusic(to volume: Float, duration: TimeInterval = 1.0) {
        guard let player = backgroundMusicPlayer else { return }
        
        let steps = 20
        let stepDuration = duration / Double(steps)
        let volumeStep = (volume - player.volume) / Float(steps)
        
        var currentStep = 0
        Timer.scheduledTimer(withTimeInterval: stepDuration, repeats: true) { timer in
            currentStep += 1
            player.volume += volumeStep
            
            if currentStep >= steps {
                timer.invalidate()
                player.volume = volume
                self.backgroundMusicVolume = volume
            }
        }
    }
    
    // MARK: - Private Methods
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    private func preloadSounds() {
        for note in MusicNote.allCases {
            loadAudioFile(for: note)
        }
    }
    
    private func loadAudioFile(for note: MusicNote) {
        guard let url = Bundle.main.url(forResource: note.audioFileName, withExtension: "mp3") ??
                       Bundle.main.url(forResource: note.audioFileName, withExtension: "wav") ??
                       Bundle.main.url(forResource: note.audioFileName, withExtension: "m4a") else {
            print("Audio file not found: \(note.audioFileName)")
            return
        }
        
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            player.volume = 0.8
            audioPlayers[note.audioFileName] = player
            print("Successfully loaded: \(note.audioFileName)")
        } catch {
            print("Error loading audio file \(note.audioFileName): \(error)")
        }
    }
    
    // Fallback method for generated tones (keeping your original implementation)
    private func playGeneratedTone(frequency: Float, duration: Float) {
        let audioEngine = AVAudioEngine()
        let mixer = audioEngine.mainMixerNode
        
        let sampleRate = Float(44100)
        let length = Int(sampleRate * duration)
        
        guard let audioFormat = AVAudioFormat(standardFormatWithSampleRate: Double(sampleRate), channels: 1) else { return }
        guard let audioBuffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: AVAudioFrameCount(length)) else { return }
        
        audioBuffer.frameLength = AVAudioFrameCount(length)
        
        let channelData = audioBuffer.floatChannelData![0]
        let amplitude: Float = 0.3
        
        for i in 0..<length {
            let sample = sin(2.0 * Float.pi * frequency * Float(i) / sampleRate) * amplitude
            let fadeOut = 1.0 - Float(i) / Float(length)
            channelData[i] = sample * fadeOut
        }
        
        let playerNode = AVAudioPlayerNode()
        audioEngine.attach(playerNode)
        audioEngine.connect(playerNode, to: mixer, format: audioFormat)
        
        do {
            try audioEngine.start()
            playerNode.scheduleBuffer(audioBuffer) {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(duration)) {
                    playerNode.stop()
                    audioEngine.stop()
                }
            }
            playerNode.play()
        } catch {
            print("Error playing generated tone: \(error)")
        }
    }
}

// MARK: - MusicNote Extension for Audio Files
extension MusicNote {
    // Audio file naming convention - customize these names to match your files
    var audioFileName: String {
        switch self {
        case .c4: return "sound"
        case .d4: return "sound2"
        case .e4: return "sound3"
        case .f4: return "sound4"    
        case .g4: return "sound5"
        case .a4: return "sound6"
        case .b4: return "sound7"
        case .b5: return "sound7"
        case .b6: return "sound7"
        }
    }
}
