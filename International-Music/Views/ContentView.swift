//
//  ContentView.swift
//  International-Music
//
//  Created by Jesse Robinson Junior Simanjuntak on 17/06/25.
//


import SwiftUI

struct ContentView: View {
    @StateObject private var cameraManager = CameraManager()
    @StateObject private var audioManager = AudioManager()
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if cameraManager.isAuthorized {
                HandDetectionView()
                    .environmentObject(cameraManager)
                    .environmentObject(audioManager)
            } else if cameraManager.permissionDenied {
                PermissionDeniedView()
            } else {
                ProgressView("Requesting Camera Permission...")
                    .foregroundColor(.white)
            }
        }
        .onAppear {
            cameraManager.requestPermission()
        }
    }
}

#Preview {
    ContentView()
}