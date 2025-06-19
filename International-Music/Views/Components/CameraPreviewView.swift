//
//  CameraPreviewView.swift
//  International-Music
//
//  Created by Jesse Robinson Junior Simanjuntak on 17/06/25.
//


import SwiftUI
import AVFoundation

struct CameraPreviewView: View {
    @EnvironmentObject var cameraManager: CameraManager
    
    var body: some View {
        CameraPreview(cameraManager: cameraManager)
            .ignoresSafeArea()
    }
}

#if os(iOS)
struct CameraPreview: UIViewRepresentable {
    let cameraManager: CameraManager
    
    func makeUIView(context: Context) -> UIView {
        // Implementation...
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // Implementation...
    }
}
#else
struct CameraPreview: View {
    let cameraManager: CameraManager
    
    var body: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.3))
            .overlay(
                Text("Camera Preview\n(macOS/Simulator)")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
            )
    }
}
#endif
