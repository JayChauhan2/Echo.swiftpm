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
    
    // Vision
    private var faceLandmarksRequest: VNDetectFaceLandmarksRequest?
    private var recordingStartTime: Date?
    
    // State buffer for smoothing UI
    private var recentPresenceStates: [PresenceState] = []
    
    override init() {
        super.init()
        setupVision()
    }
    
    private func setupVision() {
        faceLandmarksRequest = VNDetectFaceLandmarksRequest { [weak self] request, error in
            self?.handleFaceLandmarks(request: request, error: error)
        }
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
        
        currentPresence = .absent
        recordingStartTime = Date()
    }
    
    func stopAnalysis() -> VideoAnalysisResult {
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
        let engagement = Double(gazeContactFrames) / 30.0 / totalTime // Assuming ~30fps processing
        let gazeMetrics = GazeMetrics(
            eyeContactDuration: Double(gazeContactFrames) / 30.0,
            engagementRatio: min(engagement, 1.0),
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
        // Weighted average of components
        let score = (stillness + (gazeMetrics.engagementRatio) + (framingHit.isCenteredScore)) / 3.0
        
        return VideoAnalysisResult(
            events: events,
            presenceScore: score,
            movement: movementMetrics,
            gaze: gazeMetrics,
            expression: expressionMetrics,
            framing: framingHit
        )
    }
    
    private func handleFaceLandmarks(request: VNRequest, error: Error?) {
        guard let startTime = recordingStartTime else { return }
        let now = Date().timeIntervalSince(startTime)
        
        guard let results = request.results as? [VNFaceObservation], let face = results.first else {
            DispatchQueue.main.async { self.currentPresence = .absent }
            // End current streak if any
            if currentGazeStreak > 0 {
                maxGazeStreak = max(maxGazeStreak, currentGazeStreak)
                currentGazeStreak = 0
            }
            return
        }
        
        totalFaceFrames += 1
        
        // --- 1. Movement Analysis (Normalized) ---
        let currentCenter = CGPoint(x: face.boundingBox.midX, y: face.boundingBox.midY)
        if let prev = previousFaceCenter {
            let dx = currentCenter.x - prev.x
            let dy = currentCenter.y - prev.y
            let rawDist = sqrt(dx*dx + dy*dy)
            
            // Normalize distance based on face size
            // Larger face (closer) = more movement pixels for same action
            // divide by face width to get "relative movement"
            // Face width is usually 0.2 - 0.5 of screen
            let faceWidth = face.boundingBox.width
            let normalizedDist = rawDist / max(faceWidth, 0.1) // Avoid div by zero
            
            movementVelocities.append(normalizedDist)
            
            // Fidget Detection (Relative Threshold)
            // 0.05 normalized distance is significant relative to face size
            if normalizedDist > 0.05 {
                // Debounce events
                if fidgetSpikes.last.map({ now - $0 > 1.0 }) ?? true {
                    fidgetSpikes.append(now)
                    addEvent(timestamp: now, type: .fidgeting, desc: "High movement detected")
                }
            }
        }
        previousFaceCenter = currentCenter
        
        // --- 2. Gaze Analysis ---
        // Simple heuristic: Face yaw close to 0 OR eyes present
        var isLookingAtCamera = false
        if let yaw = face.yaw {
            if abs(yaw.doubleValue) < 0.2 { // ~10 degrees
                isLookingAtCamera = true
            }
        } else {
            // Fallback if no yaw: Assume looking if face is detected (rough)
            isLookingAtCamera = true
        }
        
        if isLookingAtCamera {
            gazeContactFrames += 1
            currentGazeStreak += (1.0 / 30.0) // Assume ~30fps
        } else {
            if currentGazeStreak > 0 {
                maxGazeStreak = max(maxGazeStreak, currentGazeStreak)
                currentGazeStreak = 0
            }
        }
        
        // --- 3. Expression Analysis ---
        if let landmarks = face.landmarks {
            // Smile Detection
            // Check outer lips vs face width
            if let outerLips = landmarks.outerLips {
                // Calculate bounding box of lips
                let pts = outerLips.normalizedPoints
                if let minX = pts.map({ $0.x }).min(), let maxX = pts.map({ $0.x }).max(),
                   let minY = pts.map({ $0.y }).min(), let maxY = pts.map({ $0.y }).max() {
                    
                    let width = maxX - minX
                    let height = maxY - minY
                    let ratio = width / height
                    
                    // Wide mouth relative to height usually indicates smile
                    if ratio > 2.5 {
                         if now - lastSmileTime > 2.0 {
                             smileTimestamps.append(now)
                             lastSmileTime = now
                             addEvent(timestamp: now, type: .smiling, desc: "Smile detected")
                         }
                    }
                }
            }
            
            // Energy/Variance (Eyebrow movement)
             // Simple proxy: just track if eyebrows are high?
             // For now, let's use the movement velocity as a proxy for "Energy" well enough
             // Actual expression variance is complex to calculate without baseline neutral face
        }
        
        // --- 4. Framing Analysis ---
        let faceArea = face.boundingBox.width * face.boundingBox.height
        faceRatios.append(faceArea)
        
        let devX = abs(face.boundingBox.midX - 0.5)
        let devY = abs(face.boundingBox.midY - 0.5)
        centerDeviations.append(devX + devY)
        
        // UI State Update
        var uiState: PresenceState = .grounded
        if !isLookingAtCamera { uiState = .distracted }
        else if (movementVelocities.last ?? 0) > 0.05 { uiState = .fidgeting }
        else { uiState = .grounded }
        
        // Critical Optimization: Throttle Main Thread Updates
        if uiState != lastUiState {
            lastUiState = uiState
            DispatchQueue.main.async {
                self.currentPresence = uiState
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
        
        // Create request handler (orientation fixed for portrait selfie)
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .leftMirrored, options: [:])
        
        do {
            if let request = faceLandmarksRequest {
                try handler.perform([request])
            }
        } catch {
            print("Vision failed: \(error)")
        }
    }
}
