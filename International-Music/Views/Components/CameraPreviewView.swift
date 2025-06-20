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
