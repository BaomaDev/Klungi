//
//  CameraManager.swift
//  International-Music
//
//  Created by Jesse Robinson Junior Simanjuntak on 17/06/25.
//

import AVFoundation
import Vision
import Combine
import SwiftUI

struct TrackedHand {
    let id: UUID
    var position: CGPoint
    var lastSeen: TimeInterval
    var confidence: Float
    
    init(position: CGPoint, confidence: Float) {
        self.id = UUID()
        self.position = position
        self.lastSeen = CACurrentMediaTime()
        self.confidence = confidence
    }
}



class CameraManager: NSObject, ObservableObject {
    @Published var isAuthorized = false
    @Published var permissionDenied = false
    
    private let session = AVCaptureSession()
    private let videoQueue = DispatchQueue(label: "videoQueue", qos: .userInteractive)
    private var handPoseRequest: VNDetectHumanHandPoseRequest!
    
    private var trackedHands: [TrackedHand] = []
    private let handTrackingThreshold: CGFloat = 60.0
    private let handTimeoutInterval: TimeInterval = 0.5
    private let minConfidence: Float = 0.3
    
    var previewLayer: AVCaptureVideoPreviewLayer?
    private var videoOutput: AVCaptureVideoDataOutput!
    
    // PassthroughSubject buat lempar only no need callback
    let handPointsPublisher = PassthroughSubject<[CGPoint], Never>()
    
    override init() {
        super.init()
        setupVision()
        setupCamera()
    }
    
    // MARK: - Req Permission
    func requestPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            DispatchQueue.main.async {
                self.isAuthorized = true
                self.permissionDenied = false
            }
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    self.isAuthorized = granted
                    self.permissionDenied = !granted
                }
            }
        case .denied, .restricted:
            DispatchQueue.main.async {
                self.isAuthorized = false
                self.permissionDenied = true
            }
        @unknown default:
            DispatchQueue.main.async {
                self.isAuthorized = false
                self.permissionDenied = true
            }
        }
    }
        
    func startSession() {
        if !session.isRunning {
            videoQueue.async {
                self.session.startRunning()
            }
        }
    }
    
    func stopSession() {
        if session.isRunning {
            videoQueue.async {
                self.session.stopRunning()
            }
        }
        trackedHands.removeAll()
    }
    
    // MARK: - Vision Setup
    private func setupVision() {
        handPoseRequest = VNDetectHumanHandPoseRequest()
        handPoseRequest.maximumHandCount = 2
    }
    
    private func setupCamera() {
        session.sessionPreset = .high
        
        // take camera input
        guard let frontCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            print("Front camera not available")
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: frontCamera)
            if session.canAddInput(input) {
                session.addInput(input)
            }
        } catch {
            print("Error setting up camera input: \(error)")
            return
        }
        
        // display camera output
        videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: videoQueue)
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer?.videoGravity = .resizeAspectFill
        
        // device orientation, flipped, etc
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(orientationChanged),
            name: UIDevice.orientationDidChangeNotification,
            object: nil
        )
    }
    
    @objc private func orientationChanged() {
        DispatchQueue.main.async {
            self.updatePreviewLayerOrientation()
        }
    }
    
    private func updatePreviewLayerOrientation() {
        guard let previewLayer = previewLayer else { return }
        
        let orientation = UIDevice.current.orientation
        let connection = previewLayer.connection
        
        if connection?.isVideoOrientationSupported == true {
            switch orientation {
            case .portrait:
                connection?.videoOrientation = .portrait
            case .portraitUpsideDown:
                connection?.videoOrientation = .portraitUpsideDown
            case .landscapeLeft:
                connection?.videoOrientation = .landscapeRight
            case .landscapeRight:
                connection?.videoOrientation = .landscapeLeft
            default:
                break
            }
        }
    }
    
    // MARK: - Logika buat Clean Hand Capture
    private func updateTrackedHands(with newDetections: [CGPoint], confidences: [Float]) {
        let currentTime = CACurrentMediaTime()
        
        // Remove old/lost hands
        trackedHands.removeAll { currentTime - $0.lastSeen > handTimeoutInterval }
        
        var updatedHands: [TrackedHand] = []
        var usedDetections = Set<Int>()
        
        // value buat new detection on hand
        for existingHand in trackedHands {
            var bestMatch: (index: Int, distance: CGFloat)? = nil
            
            for (index, newPosition) in newDetections.enumerated() {
                if usedDetections.contains(index) { continue }
                
                let distance = sqrt(pow(existingHand.position.x - newPosition.x, 2) +
                                  pow(existingHand.position.y - newPosition.y, 2))
                
                if distance < handTrackingThreshold {
                    if bestMatch == nil || distance < bestMatch!.distance {
                        bestMatch = (index, distance)
                    }
                }
            }
            
            if let match = bestMatch {
                // Update existing hand
                var updatedHand = existingHand
                updatedHand.position = newDetections[match.index]
                updatedHand.lastSeen = currentTime
                updatedHand.confidence = confidences[match.index]
                updatedHands.append(updatedHand)
                usedDetections.insert(match.index)
            }
        }
        
        // Add new hands for unmatched detections
        for (index, newPosition) in newDetections.enumerated() {
            if !usedDetections.contains(index) && confidences[index] >= minConfidence {
                let newHand = TrackedHand(position: newPosition, confidence: confidences[index])
                updatedHands.append(newHand)
            }
        }
        
        // Sort hands by position (left to right) for consistent ordering
        updatedHands.sort { $0.position.x < $1.position.x }
        
        // Limit to maximum 2 hands
        if updatedHands.count > 2 {
            // Keep the 2 hands with highest confidence
            updatedHands = Array(updatedHands.sorted { $0.confidence > $1.confidence }.prefix(2))
            updatedHands.sort { $0.position.x < $1.position.x } // Re-sort by position
        }
        
        trackedHands = updatedHands
        
        // Publish stable hand positions
        let stablePositions = trackedHands.map { $0.position }
        DispatchQueue.main.async {
            self.handPointsPublisher.send(stablePositions)
        }
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
        
        do {
            try handler.perform([handPoseRequest])
            
            guard let results = handPoseRequest.results else { return }
            
            let (handPositions, confidences) = processHandDetectionResults(results)
            updateTrackedHands(with: handPositions, confidences: confidences)
            
        } catch {
            print("Error performing hand pose request: \(error)")
        }
    }
    
    private func processHandDetectionResults(_ results: [VNHumanHandPoseObservation]) -> ([CGPoint], [Float]) {
        var handPositions: [CGPoint] = []
        var confidences: [Float] = []
        
        for observation in results {
            guard
                let thumbPoint = try? observation.recognizedPoint(.thumbTip),
                let indexPoint = try? observation.recognizedPoint(.indexTip)
            else {
                continue
            }
            
            // Cek confidence keduanya
            if thumbPoint.confidence >= minConfidence && indexPoint.confidence >= minConfidence {
                // ambil titik tengah antara thumb dan index
                let avgX = (thumbPoint.location.x + indexPoint.location.x) / 2
                let avgY = (thumbPoint.location.y + indexPoint.location.y) / 2
                let averagePoint = CGPoint(x: avgX, y: avgY)
                
                let convertedPoint = previewLayer?.layerPointConverted(
                    fromCaptureDevicePoint: CGPoint(x: averagePoint.x, y: 1 - averagePoint.y)
                ) ?? .zero
                
                handPositions.append(convertedPoint)
                
                // Ambil confidence rata-rata (atau bisa ambil salah satu jika ingin)
                let averageConfidence = (thumbPoint.confidence + indexPoint.confidence) / 2
                confidences.append(averageConfidence)
            }
        }
        
//        for observation in results {
//            // Cuma ambil index finger tip aja
//            guard let indexPoint = try? observation.recognizedPoint(.indexTip) else {
//                continue
//            }
//            
//            // Cek confidence index finger
//            if indexPoint.confidence >= minConfidence {
//                // Langsung pakai posisi index tip, gak perlu rata-rata
//                let convertedPoint = previewLayer?.layerPointConverted(
//                    fromCaptureDevicePoint: CGPoint(x: indexPoint.location.x, y: 1 - indexPoint.location.y)
//                ) ?? .zero
//                
//                handPositions.append(convertedPoint)
//                
//                // Langsung pakai confidence index finger
//                confidences.append(indexPoint.confidence)
//            }
//        }
        
        return (handPositions, confidences)
    }
}
