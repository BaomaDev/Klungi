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
    @State private var orientation = UIDeviceOrientation.unknown
    
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
            
            // Enable orientation notifications
            #if os(iOS)
            UIDevice.current.beginGeneratingDeviceOrientationNotifications()
            #endif
        }
        .onDisappear {
            #if os(iOS)
            UIDevice.current.endGeneratingDeviceOrientationNotifications()
            #endif
        }
        .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
            #if os(iOS)
            orientation = UIDevice.current.orientation
            #endif
        }
        // Support all orientations
        .supportedOrientations(.all)
    }
}

// Extension to support orientation changes
extension View {
    func supportedOrientations(_ orientations: UIInterfaceOrientationMask) -> some View {
        self.onAppear {
            #if os(iOS)
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: orientations))
            }
            #endif
        }
    }
}

#Preview {
    ContentView()
}
