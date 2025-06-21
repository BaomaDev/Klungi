//
//  CameraManager.swift - Optimized for Jitter Reduction
//

import AVFoundation
import Vision
import Combine
import SwiftUI

struct TrackedHand {
    let id: UUID
    var position: CGPoint
    var smoothedPosition: CGPoint  // NEW: Smoothed position
    var lastSeen: TimeInterval
    var confidence: Float
    var isPinching: Bool
    var pinchDistance: CGFloat
    var lastShakePosition: CGPoint
    var shakeIntensity: CGFloat
    
    init(position: CGPoint, confidence: Float, isPinching: Bool = false, pinchDistance: CGFloat = 0) {
        self.id = UUID()
        self.position = position
        self.smoothedPosition = position  // Initialize smoothed position
        self.lastSeen = CACurrentMediaTime()
        self.confidence = confidence
        self.isPinching = isPinching
        self.pinchDistance = pinchDistance
        self.lastShakePosition = position
        self.shakeIntensity = 0
    }
}

class CameraManager: NSObject, ObservableObject {
    @Published var isAuthorized = false
    @Published var permissionDenied = false
    
    private let session = AVCaptureSession()
    private let videoQueue = DispatchQueue(label: "videoQueue", qos: .userInteractive)
    private var handPoseRequest: VNDetectHumanHandPoseRequest!
    
    private var trackedHands: [TrackedHand] = []
    private let handTrackingThreshold: CGFloat = 80.0  // Increased threshold
    private let handTimeoutInterval: TimeInterval = 0.5
    private let minConfidence: Float = 0.5  // Increased minimum confidence
    
    // PINCH DETECTION SETTINGS - More stable thresholds
    private let pinchThreshold: CGFloat = 0.08  // Slightly increased
    private let shakeThreshold: CGFloat = 20.0  // Increased shake threshold
    
    // NEW: Smoothing parameters
    private let positionSmoothingFactor: CGFloat = 0.3  // Lower = more smoothing
    private let pinchSmoothingFrames = 3  // Require 3 consecutive frames for pinch state change
    private var pinchStateHistory: [[Bool]] = [[], []]  // Track pinch history for each hand
    
    // NEW: Frame rate limiting
    private var lastProcessTime: TimeInterval = 0
    private let minProcessInterval: TimeInterval = 1.0/30.0  // Limit to 30 FPS
    
    var previewLayer: AVCaptureVideoPreviewLayer?
    private var videoOutput: AVCaptureVideoDataOutput!
    
    // Publisher for hand data with pinch and shake info
    let handDataPublisher = PassthroughSubject<[TrackedHand], Never>()
    
    override init() {
        super.init()
        setupVision()
        setupCamera()
    }
    
    // MARK: - Permission Methods (unchanged)
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
        pinchStateHistory = [[], []]
    }
    
    // MARK: - Vision Setup
    private func setupVision() {
        handPoseRequest = VNDetectHumanHandPoseRequest()
        handPoseRequest.maximumHandCount = 2
    }
    
    private func setupCamera() {
        session.sessionPreset = .medium  // Changed from .high to reduce processing load
        
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
        
        // NEW: Reduce video output frame rate
        if let connection = videoOutput.connection(with: .video) {
            connection.videoOrientation = .portrait
        }
        
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer?.videoGravity = .resizeAspectFill
        
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
    
    // MARK: - NEW: Smoothed Hand Tracking
    private func updateTrackedHands(with detections: [(position: CGPoint, confidence: Float, isPinching: Bool, pinchDistance: CGFloat)]) {
        let currentTime = CACurrentMediaTime()
        
        // Remove old hands
        trackedHands.removeAll { currentTime - $0.lastSeen > handTimeoutInterval }
        
        var updatedHands: [TrackedHand] = []
        var usedDetections = Set<Int>()
        
        // Update existing hands with smoothing
        for (handIndex, existingHand) in trackedHands.enumerated() {
            var bestMatch: (index: Int, distance: CGFloat)? = nil
            
            for (index, detection) in detections.enumerated() {
                if usedDetections.contains(index) { continue }
                
                let distance = sqrt(pow(existingHand.position.x - detection.position.x, 2) +
                                  pow(existingHand.position.y - detection.position.y, 2))
                
                if distance < handTrackingThreshold {
                    if bestMatch == nil || distance < bestMatch!.distance {
                        bestMatch = (index, distance)
                    }
                }
            }
            
            if let match = bestMatch {
                let detection = detections[match.index]
                
                // Apply position smoothing
                let smoothedX = existingHand.smoothedPosition.x + (detection.position.x - existingHand.smoothedPosition.x) * positionSmoothingFactor
                let smoothedY = existingHand.smoothedPosition.y + (detection.position.y - existingHand.smoothedPosition.y) * positionSmoothingFactor
                let smoothedPosition = CGPoint(x: smoothedX, y: smoothedY)
                
                // Apply pinch state smoothing
                let smoothedPinchState = getSmoothedPinchState(for: handIndex, newState: detection.isPinching)
                
                // Calculate shake intensity with smoothed position
                let shakeDistance = sqrt(pow(smoothedPosition.x - existingHand.lastShakePosition.x, 2) +
                                       pow(smoothedPosition.y - existingHand.lastShakePosition.y, 2))
                
                var updatedHand = existingHand
                updatedHand.position = detection.position
                updatedHand.smoothedPosition = smoothedPosition
                updatedHand.lastSeen = currentTime
                updatedHand.confidence = detection.confidence
                updatedHand.isPinching = smoothedPinchState
                updatedHand.pinchDistance = detection.pinchDistance
                
                // Update shake detection with higher threshold
                if shakeDistance > shakeThreshold {
                    updatedHand.shakeIntensity = min(shakeDistance, 50.0)  // Cap shake intensity
                    updatedHand.lastShakePosition = smoothedPosition
                } else {
                    updatedHand.shakeIntensity = max(0, updatedHand.shakeIntensity - 5) // Faster decay
                }
                
                updatedHands.append(updatedHand)
                usedDetections.insert(match.index)
            }
        }
        
        // Add new hands
        for (index, detection) in detections.enumerated() {
            if !usedDetections.contains(index) && detection.confidence >= minConfidence {
                let newHand = TrackedHand(
                    position: detection.position,
                    confidence: detection.confidence,
                    isPinching: detection.isPinching,
                    pinchDistance: detection.pinchDistance
                )
                updatedHands.append(newHand)
                
                // Initialize pinch history for new hand
                if pinchStateHistory.count <= updatedHands.count - 1 {
                    pinchStateHistory.append([])
                }
            }
        }
        
        // Sort hands by position (left to right)
        updatedHands.sort { $0.smoothedPosition.x < $1.smoothedPosition.x }
        
        // Limit to 2 hands
        if updatedHands.count > 2 {
            updatedHands = Array(updatedHands.sorted { $0.confidence > $1.confidence }.prefix(2))
            updatedHands.sort { $0.smoothedPosition.x < $1.smoothedPosition.x }
        }
        
        trackedHands = updatedHands
        
        // Publish hand data (reduced frequency)
        DispatchQueue.main.async {
            self.handDataPublisher.send(self.trackedHands)
        }
    }
    
    // NEW: Pinch state smoothing
    private func getSmoothedPinchState(for handIndex: Int, newState: Bool) -> Bool {
        // Ensure we have enough history arrays
        while pinchStateHistory.count <= handIndex {
            pinchStateHistory.append([])
        }
        
        // Add new state to history
        pinchStateHistory[handIndex].append(newState)
        
        // Keep only recent history
        if pinchStateHistory[handIndex].count > pinchSmoothingFrames {
            pinchStateHistory[handIndex].removeFirst()
        }
        
        // Return smoothed state (majority vote)
        let trueCount = pinchStateHistory[handIndex].filter { $0 }.count
        return trueCount >= pinchSmoothingFrames / 2
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let currentTime = CACurrentMediaTime()
        
        // NEW: Frame rate limiting
        if currentTime - lastProcessTime < minProcessInterval {
            return
        }
        lastProcessTime = currentTime
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
        
        do {
            try handler.perform([handPoseRequest])
            
            guard let results = handPoseRequest.results else { return }
            
            let detections = processHandDetectionResults(results)
            updateTrackedHands(with: detections)
            
        } catch {
            print("Error performing hand pose request: \(error)")
        }
    }
    
    private func processHandDetectionResults(_ results: [VNHumanHandPoseObservation]) -> [(position: CGPoint, confidence: Float, isPinching: Bool, pinchDistance: CGFloat)] {
        var detections: [(position: CGPoint, confidence: Float, isPinching: Bool, pinchDistance: CGFloat)] = []
        
        for observation in results {
            guard
                let thumbPoint = try? observation.recognizedPoint(.thumbTip),
                let indexPoint = try? observation.recognizedPoint(.indexTip)
            else {
                continue
            }
            
            if thumbPoint.confidence >= minConfidence && indexPoint.confidence >= minConfidence {
                // Calculate average position
                let avgX = (thumbPoint.location.x + indexPoint.location.x) / 2
                let avgY = (thumbPoint.location.y + indexPoint.location.y) / 2
                let averagePoint = CGPoint(x: avgX, y: avgY)
                
                let convertedPoint = previewLayer?.layerPointConverted(
                    fromCaptureDevicePoint: CGPoint(x: averagePoint.x, y: 1 - averagePoint.y)
                ) ?? .zero
                
                // Calculate pinch distance with improved threshold
                let pinchDistance = sqrt(pow(thumbPoint.location.x - indexPoint.location.x, 2) +
                                       pow(thumbPoint.location.y - indexPoint.location.y, 2))
                
                // More conservative pinch detection
                let isPinching = pinchDistance < pinchThreshold
                
                let averageConfidence = (thumbPoint.confidence + indexPoint.confidence) / 2
                
                detections.append((
                    position: convertedPoint,
                    confidence: averageConfidence,
                    isPinching: isPinching,
                    pinchDistance: pinchDistance
                ))
            }
        }
        
        return detections
    }
}
