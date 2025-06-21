//
//  PracticeModeView.swift
//  International-Music
//
//  Created by Jesse Robinson Junior Simanjuntak on 21/06/25.
//


//
//  PracticeModeView.swift
//  International-Music
//
//  Created by Jesse Robinson Junior Simanjuntak on 21/06/25.
//

import SwiftUI

struct PracticeModeView: View {
    @Environment(\.presentationMode) var presentationMode
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
            
            // Back to Home Button
            VStack {
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
                    .padding(.leading, 20)
                    .padding(.top, 20)
                    
                    Spacer()
                    
                    // Practice Mode Label
                    VStack(spacing: 2) {
                        Text("Practice Mode")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                        Text("Free Play")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .padding(.trailing, 20)
                    .padding(.top, 20)
                }
                Spacer()
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            cameraManager.requestPermission()
        }
    }
}

#Preview {
    PracticeModeView()
}