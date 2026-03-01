import Vision
import AVFoundation

class VideoAnalyzer: NSObject, ObservableObject {
    @Published var currentPresence: PresenceState = .absent
    
    // MARK: - Collected Data
    private var lastUiState: PresenceState = .absent
    private var events: [VisualEvent] = []
    
    // Movement Tracking
    private var previousFaceCenter: CGPoint?
    private var movementVelocities: [Double] = []
    private var fidgetSpikes: [TimeInterval] = []
    
    // Gaze Tracking
    private var gazeContactFrames: Int = 0
    private var totalFaceFrames: Int = 0
    private var currentGazeStreak: Double = 0
    private var maxGazeStreak: Double = 0
    private var gazeStreakTimes: [TimeInterval] = []
    
    // Expression Tracking
    private var expressionVariances: [Double] = []
    private var smileTimestamps: [TimeInterval] = []
    private var lastSmileTime: TimeInterval = 0
    
    // Framing Tracking
    private var faceRatios: [Double] = []
    private var centerDeviations: [Double] = []
    private var postureIssueFrames: Int = 0

    // Presence smoothing
    private var consecutiveNoFaceFrames: Int = 0
    private var consecutiveFaceFrames: Int = 0
    
    // Vision
    private var faceLandmarksRequest: VNDetectFaceLandmarksRequest?
    private var recordingStartTime: Date?
    
    // State buffer for smoothing UI
    private var recentPresenceStates: [PresenceState] = []
    private var lastFrameTime: TimeInterval = 0
    
    // Thread safety
    private let analysisQueue = DispatchQueue(label: "com.echo.videoAnalysis", qos: .userInteractive)
    
    override init() {
        super.init()
        setupVision()
    }
    
    private func setupVision() {
        let request = VNDetectFaceLandmarksRequest { [weak self] request, error in
            self?.handleFaceLandmarks(request: request, error: error)
        }
        // Revision 3 is more accurate for lip landmarks
        request.revision = VNDetectFaceLandmarksRequestRevision3
        faceLandmarksRequest = request
    }
    
    func startAnalysis() {
        // Reset all metrics
        events.removeAll()
        movementVelocities.removeAll()
        fidgetSpikes.removeAll()
        gazeContactFrames = 0
        totalFaceFrames = 0
        currentGazeStreak = 0
        maxGazeStreak = 0
        expressionVariances.removeAll()
        smileTimestamps.removeAll()
        faceRatios.removeAll()
        centerDeviations.removeAll()
        postureIssueFrames = 0
        
        previousFaceCenter = nil
        lastUiState = .absent
        recentPresenceStates.removeAll()
        
        consecutiveNoFaceFrames = 0
        consecutiveFaceFrames = 0
        // Start optimistic: assume present until proven absent to avoid initial flicker
        currentPresence = .present
        lastUiState = .present
        recordingStartTime = Date()
    }
    
    func stopAnalysis() -> VideoAnalysisResult {
        return analysisQueue.sync {
            let duration = Date().timeIntervalSince(recordingStartTime ?? Date())
            
            // 1. Process Movement
            let avgVelocity = movementVelocities.isEmpty ? 0 : movementVelocities.reduce(0, +) / Double(movementVelocities.count)
            let stillness = max(0, 1.0 - (avgVelocity * 5.0)) // Heuristic scaling
            let movementMetrics = HeadMovementMetrics(
                averageVelocity: avgVelocity,
                stillnessScore: stillness,
                fidgetIntervals: fidgetSpikes
            )
            
            // 2. Process Gaze
            let totalTime = max(duration, 1.0)
            let engagement = totalFaceFrames > 0 ? Double(gazeContactFrames) / Double(totalFaceFrames) : 0
            let gazeMetrics = GazeMetrics(
                eyeContactDuration: totalTime * engagement,
                engagementRatio: engagement,
                longestStreak: maxGazeStreak
            )
            
            // 3. Process Expression
            let energy = expressionVariances.isEmpty ? 0 : expressionVariances.reduce(0, +) / Double(expressionVariances.count)
            let expressionMetrics = ExpressionMetrics(
                energyScore: energy * 1000, // Scale up small variance
                smileCount: smileTimestamps.count,
                smileTimestamps: smileTimestamps
            )
            
            // 4. Process Framing
            let avgRatio = faceRatios.isEmpty ? 0 : faceRatios.reduce(0, +) / Double(faceRatios.count)
            let avgDeviation = centerDeviations.isEmpty ? 0 : centerDeviations.reduce(0, +) / Double(centerDeviations.count)
            let framingHit = FramingMetrics(
                averageFaceRatio: avgRatio,
                isCenteredScore: max(0, 1.0 - avgDeviation),
                postureIssueDetected: postureIssueFrames > 30 // > 1 second accumulated
            )
            
            // Final Score
            let score = (stillness + (gazeMetrics.engagementRatio) + (framingHit.isCenteredScore)) / 3.0

            if events.isEmpty {
                addEvent(timestamp: 0.0, type: .present, desc: "Session recorded")
            }
            
            return VideoAnalysisResult(
                events: events,
                presenceScore: score,
                movement: movementMetrics,
                gaze: gazeMetrics,
                expression: expressionMetrics,
                framing: framingHit
            )
        }
    }
    
    private func handleFaceLandmarks(request: VNRequest, error: Error?) {
        let startTime = recordingStartTime
        let now = startTime.map { Date().timeIntervalSince($0) } ?? 0
        
        guard let results = request.results as? [VNFaceObservation], let face = results.first else {
            analysisQueue.async {
                self.consecutiveNoFaceFrames += 1
                self.consecutiveFaceFrames = 0
                // Only mark absent after ~0.3s without a face (~9 frames at 30fps)
                if self.consecutiveNoFaceFrames > 9 {
                    DispatchQueue.main.async { self.currentPresence = .absent }
                    self.lastUiState = .absent
                }
            }
            return
        }
        
        analysisQueue.async {
            self.consecutiveFaceFrames += 1
            self.consecutiveNoFaceFrames = 0
            if self.consecutiveFaceFrames >= 2 && self.lastUiState == .absent {
                if let startTime = startTime {
                    self.addEvent(timestamp: now, type: .present, desc: "Face detected")
                }
                DispatchQueue.main.async { self.currentPresence = .present }
                self.lastUiState = .present
            }
            
            if startTime != nil {
                self.totalFaceFrames += 1
            }
            
            // --- 1. Movement Analysis (Normalized) ---
            let currentCenter = CGPoint(x: face.boundingBox.midX, y: face.boundingBox.midY)
            if let prev = self.previousFaceCenter, startTime != nil {
                let dx = currentCenter.x - prev.x
                let dy = currentCenter.y - prev.y
                let rawDist = sqrt(dx*dx + dy*dy)
                let faceWidth = face.boundingBox.width
                let normalizedDist = rawDist / max(faceWidth, 0.1)
                
                self.movementVelocities.append(normalizedDist)
                
                if normalizedDist > 0.04 {
                    if self.fidgetSpikes.last.map({ now - $0 > 0.8 }) ?? true {
                        self.fidgetSpikes.append(now)
                        self.addEvent(timestamp: now, type: .fidgeting, desc: "High movement detected")
                    }
                }
            }
            if startTime != nil {
                self.previousFaceCenter = currentCenter
            }
            
            // --- 2. Gaze Analysis ---
            var isLookingAtCamera = false
            if let yaw = face.yaw {
                if abs(yaw.doubleValue) < 0.35 {
                    isLookingAtCamera = true
                }
            } else {
                isLookingAtCamera = true
            }
            
            self.recentPresenceStates.append(isLookingAtCamera ? .present : .distracted)
            if self.recentPresenceStates.count > 10 { self.recentPresenceStates.removeFirst() }
            
            if isLookingAtCamera && startTime != nil {
                self.gazeContactFrames += 1
                if self.lastFrameTime > 0 {
                    let delta = now - self.lastFrameTime
                    self.currentGazeStreak += delta
                }
            } else if startTime != nil {
                if self.currentGazeStreak > 0 {
                    self.maxGazeStreak = max(self.maxGazeStreak, self.currentGazeStreak)
                    self.currentGazeStreak = 0
                }
            }
            self.lastFrameTime = now
            
            // --- 3. Expression Analysis ---
            if let landmarks = face.landmarks {
                if let outerLips = landmarks.outerLips {
                    let pts = outerLips.normalizedPoints
                    if pts.count >= 2 {
                        // Find corners and vertical extremas
                        let leftCorner = pts.min(by: { $0.x < $1.x })!
                        let rightCorner = pts.max(by: { $0.x < $1.x })!
                        let bottomCenter = pts.min(by: { $0.y < $1.y })!
                        let topCenter = pts.max(by: { $0.y < $1.y })!
                        
                        let mouthWidth = rightCorner.x - leftCorner.x
                        let mouthHeight = topCenter.y - bottomCenter.y
                        let aspect = mouthWidth / max(mouthHeight, 0.01)
                        
                        // Curvature: Average corner height relative to the bottom center
                        let avgCornerY = (leftCorner.y + rightCorner.y) / 2.0
                        let curvature = avgCornerY - bottomCenter.y
                        
                        // Score calculation:
                        // A smile typically has a high aspect ratio (wide) AND positive curvature (upward corners)
                        // Using a curvature-dominant scoring for better accuracy:
                        let smileScore = (aspect - 2.2) + (curvature * 20.0) 
                        
                        self.expressionVariances.append(min(max(smileScore / 2.0, 0.0), 1.0))
                        
                        // Detect a distinct smile event
                        // 0.5 is a robust threshold for a clear smile
                        if smileScore > 0.5 { 
                            if startTime != nil && now - self.lastSmileTime > 1.0 {
                                self.smileTimestamps.append(now)
                                self.lastSmileTime = now
                                self.addEvent(timestamp: now, type: .smiling, desc: "Smile detected")
                            }
                        }
                    }
                }
            }
            
            // --- 4. Framing Analysis ---
            if startTime != nil {
                let faceArea = face.boundingBox.width * face.boundingBox.height
                self.faceRatios.append(faceArea)
                let devX = abs(face.boundingBox.midX - 0.5)
                let devY = abs(face.boundingBox.midY - 0.5)
                self.centerDeviations.append(devX + devY)
            }
            
            // UI State Update
            var uiState: PresenceState = .grounded
            if !isLookingAtCamera { uiState = .distracted }
            else if (self.movementVelocities.last ?? 0) > 0.04 { uiState = .fidgeting }
            else { uiState = .grounded }

            if uiState != self.lastUiState {
                self.lastUiState = uiState
                DispatchQueue.main.async {
                    self.currentPresence = uiState
                }
            }
        }
    }
    
    private func addEvent(timestamp: TimeInterval, type: PresenceState, desc: String) {
        // Debounce generic events
        DispatchQueue.main.async {
            self.events.append(VisualEvent(timestamp: timestamp, type: type, description: desc))
        }
    }
}

extension VideoAnalyzer: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        // Dynamic orientation handling
        // Front camera is mirrored by default in this app's CameraManager
        let orientation: CGImagePropertyOrientation
        switch connection.videoOrientation {
        case .portrait: orientation = .leftMirrored
        case .portraitUpsideDown: orientation = .rightMirrored
        case .landscapeLeft: orientation = .downMirrored
        case .landscapeRight: orientation = .upMirrored
        @unknown default: orientation = .leftMirrored
        }
        
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: orientation, options: [:])
        
        do {
            if let request = faceLandmarksRequest {
                try handler.perform([request])
            }
        } catch {
            print("Vision failed: \(error)")
        }
    }
}
