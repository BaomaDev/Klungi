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

// Stable hand tracking data structure
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
    
    // Stable hand tracking
    private var trackedHands: [TrackedHand] = []
    private let handTrackingThreshold: CGFloat = 60.0 // Distance threshold for hand matching
    private let handTimeoutInterval: TimeInterval = 0.5 // How long before a hand is considered lost
    private let minConfidence: Float = 0.3
    
    #if os(iOS)
    var previewLayer: AVCaptureVideoPreviewLayer?
    private var videoOutput: AVCaptureVideoDataOutput!
    #endif
    
    let handPointsPublisher = PassthroughSubject<[CGPoint], Never>()
    
    override init() {
        super.init()
        setupVision()
        #if os(iOS)
        setupCamera()
        #endif
    }
    
    // MARK: - Public Methods
    func requestPermission() {
        #if os(iOS)
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
        #else
        // For macOS/other platforms, simulate permission granted
        DispatchQueue.main.async {
            self.isAuthorized = true
            self.permissionDenied = false
        }
        #endif
    }
    
    func startSession() {
        #if os(iOS)
        if !session.isRunning {
            videoQueue.async {
                self.session.startRunning()
            }
        }
        #else
        // For non-iOS platforms, simulate stable hand detection
        simulateStableHandDetection()
        #endif
    }
    
    func stopSession() {
        #if os(iOS)
        if session.isRunning {
            videoQueue.async {
                self.session.stopRunning()
            }
        }
        #endif
        trackedHands.removeAll()
    }
    
    // MARK: - Private Methods
    private func setupVision() {
        handPoseRequest = VNDetectHumanHandPoseRequest()
        handPoseRequest.maximumHandCount = 2
    }
    
    #if os(iOS)
    private func setupCamera() {
        session.sessionPreset = .high
        
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
        
        videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: videoQueue)
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer?.videoGravity = .resizeAspectFill
        
        // Enable device orientation changes
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
    #else
    private func simulateStableHandDetection() {
        var hand1Position = CGPoint(x: 200, y: 300)
        var hand2Position = CGPoint(x: 600, y: 400)
        
        Timer.scheduledTimer(withTimeInterval: 0.033, repeats: true) { _ in // ~30 FPS
            let screenSize = NSScreen.main?.frame.size ?? CGSize(width: 800, height: 600)
            
            // Smooth movement simulation
            hand1Position.x += CGFloat.random(in: -10...10)
            hand1Position.y += CGFloat.random(in: -10...10)
            hand2Position.x += CGFloat.random(in: -10...10)
            hand2Position.y += CGFloat.random(in: -10...10)
            
            // Keep hands within bounds
            hand1Position.x = max(50, min(screenSize.width - 50, hand1Position.x))
            hand1Position.y = max(50, min(screenSize.height - 50, hand1Position.y))
            hand2Position.x = max(50, min(screenSize.width - 50, hand2Position.x))
            hand2Position.y = max(50, min(screenSize.height - 50, hand2Position.y))
            
            let stableHands = [hand1Position, hand2Position]
            
            DispatchQueue.main.async {
                self.handPointsPublisher.send(stableHands)
            }
        }
    }
    #endif
    
    // MARK: - Stable Hand Tracking Logic
    private func updateTrackedHands(with newDetections: [CGPoint], confidences: [Float]) {
        let currentTime = CACurrentMediaTime()
        
        // Remove old/lost hands
        trackedHands.removeAll { currentTime - $0.lastSeen > handTimeoutInterval }
        
        var updatedHands: [TrackedHand] = []
        var usedDetections = Set<Int>()
        
        // Try to match existing hands with new detections
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
#if os(iOS)
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
                // Misalnya ambil titik tengah antara thumb dan index
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
        
        return (handPositions, confidences)
    }
}
#endif
