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
        case .c4: return "sound"      // Should match your file: note_c4.mp3
        case .d4: return "sound2"     // Should match your file: note_d4.mp3
        case .e4: return "sound3"    // Should match your file: note_e4.mp3
        case .f4: return "sound4"     // Should match your file: note_f4.mp3
        case .g4: return "sound5"     // Should match your file: note_g4.mp3
        case .a4: return "sound6"     // Should match your file: note_a4.mp3
        case .b4: return "sound7"    // Should match your file: note_b4.mp3
        }
        
        // Alternative naming patterns you can use instead:
        
        // Pattern 1: Simple note names
        // return rawValue.lowercased()  // Results in: "c4", "d4", etc.
        
        // Pattern 2: Piano prefix
        // return "piano_" + rawValue.lowercased()  // Results in: "piano_c4", "piano_d4", etc.
        
        // Pattern 3: Angklung sounds (matching your image assets)
        // return "angklung_" + rawValue.lowercased()  // Results in: "angklung_c4", etc.
    }
}
