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
    
    func makeUIView(context: Context) -> PreviewUIView {
        let view = PreviewUIView()
        
        DispatchQueue.main.async {
            if let previewLayer = cameraManager.previewLayer {
                previewLayer.frame = view.bounds
                previewLayer.videoGravity = .resizeAspectFill
                view.layer.addSublayer(previewLayer)
                view.previewLayer = previewLayer
            }
        }
        
        return view
    }
    
    func updateUIView(_ uiView: PreviewUIView, context: Context) {
        if let previewLayer = cameraManager.previewLayer {
            DispatchQueue.main.async {
                previewLayer.frame = uiView.bounds
                uiView.previewLayer = previewLayer
            }
        }
    }
}

class PreviewUIView: UIView {
    var previewLayer: AVCaptureVideoPreviewLayer?
    
    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer?.frame = bounds
    }
}
#else
struct CameraPreview: View {
    let cameraManager: CameraManager
    @State private var mockHandPosition1 = CGPoint(x: 100, y: 200)
    @State private var mockHandPosition2 = CGPoint(x: 300, y: 400)
    
    var body: some View {
        GeometryReader { geometry in
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .overlay(
                    VStack {
                        Text("Camera Preview")
                            .font(.title2)
                            .foregroundColor(.white)
                        Text("(macOS/Simulator)")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                        
                        Spacer()
                        
                        // Mock hand indicators for testing
                        HStack {
                            Circle()
                                .fill(Color.blue.opacity(0.6))
                                .frame(width: 20, height: 20)
                                .overlay(Text("L").font(.caption).foregroundColor(.white))
                            
                            Text("Mock Hand Tracking")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                            
                            Circle()
                                .fill(Color.green.opacity(0.6))
                                .frame(width: 20, height: 20)
                                .overlay(Text("R").font(.caption).foregroundColor(.white))
                        }
                        .padding(.bottom, 50)
                    }
                    .multilineTextAlignment(.center)
            )
            .onAppear {
                startMockHandTracking(in: geometry.size)
            }
        }
    }
    
    private func startMockHandTracking(in size: CGSize) {
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            // Simulate moving hands
            mockHandPosition1.x += CGFloat.random(in: -20...20)
            mockHandPosition1.y += CGFloat.random(in: -20...20)
            mockHandPosition2.x += CGFloat.random(in: -20...20)
            mockHandPosition2.y += CGFloat.random(in: -20...20)
            
            // Keep hands within bounds
            mockHandPosition1.x = max(50, min(size.width - 50, mockHandPosition1.x))
            mockHandPosition1.y = max(50, min(size.height - 50, mockHandPosition1.y))
            mockHandPosition2.x = max(50, min(size.width - 50, mockHandPosition2.x))
            mockHandPosition2.y = max(50, min(size.height - 50, mockHandPosition2.y))
            
            cameraManager.handPointsPublisher.send([mockHandPosition1, mockHandPosition2])
        }
    }
}
#endif
