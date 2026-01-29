import Vision
import AVFoundation

class VideoAnalyzer: NSObject, ObservableObject {
    @Published var currentPresence: PresenceState = .absent
    
    private var events: [VisualEvent] = []
    private var presenceScores: [Double] = []
    private var faceLandmarksRequest: VNDetectFaceLandmarksRequest?
    
    // Tracking state
    private var lastLookAwayTime: TimeInterval = 0
    private var lastPresenceCheckTime: TimeInterval = 0
    private var recordingStartTime: Date?
    
    // Smoothing
    private var recentYaws: [Double] = []
    private let yawWindowSize = 5
    
    override init() {
        super.init()
        setupVision()
    }
    
    private func setupVision() {
        faceLandmarksRequest = VNDetectFaceLandmarksRequest { [weak self] request, error in
            self?.handleFaceLandmarks(request: request, error: error)
        }
    }
    
    func cleanUp() {
        events.removeAll()
        presenceScores.removeAll()
        recentYaws.removeAll()
        currentPresence = .absent
    }
    
    func startAnalysis() {
        cleanUp()
        recordingStartTime = Date()
    }
    
    func stopAnalysis() -> VideoAnalysisResult {
        // Calculate final scores
        let totalSamples = Double(presenceScores.count)
        let avgPresence = presenceScores.isEmpty ? 0.0 : presenceScores.reduce(0, +) / totalSamples
        
        // Stability based on ratio of 'steady' frames (1.0) vs 'distracted' (0.5) vs 'absent' (0.0)
        // We can just count distracted events relative to total time
        let distractedCount = events.filter { $0.type == .distracted }.count
        // Rough estimate: reduce stability by 5% for each distraction event
        let stability = max(0.0, 1.0 - (Double(distractedCount) * 0.05))
        
        return VideoAnalysisResult(
            events: events,
            presenceScore: avgPresence,
            gazeStabilityScore: stability
        )
    }
    
    private func handleFaceLandmarks(request: VNRequest, error: Error?) {
        guard let results = request.results as? [VNFaceObservation], let result = results.first else {
            // No face found
            // Clear recent yaws so we don't start with old data when face reappears
            if !recentYaws.isEmpty { recentYaws.removeAll() }
            updatePresence(.absent)
            return
        }
        
        // Face found
        // Analyze Gaze / Pose
        if let landmarks = result.landmarks {
            if let yaw = result.yaw {
                let currentYaw = yaw.doubleValue
                recentYaws.append(currentYaw)
                if recentYaws.count > yawWindowSize {
                    recentYaws.removeFirst()
                }
                
                let avgYaw = recentYaws.reduce(0, +) / Double(recentYaws.count)
                let absYaw = abs(avgYaw)
                
                if absYaw > 0.5 { // Significant turn (>~28 degrees)
                     updatePresence(.distracted)
                } else {
                    updatePresence(.present)
                }
            } else {
                updatePresence(.present)
            }
        } else {
             updatePresence(.present)
        }
    }
    
    private func updatePresence(_ newState: PresenceState) {
        // Debounce slightly on main thread updates if needed, but currentPresence is for UI
        DispatchQueue.main.async {
            self.currentPresence = newState
        }
        
        guard let startTime = recordingStartTime else { return }
        let now = Date().timeIntervalSince(startTime)
        
        // Rate limit logging/scoring (2Hz)
        if now - lastPresenceCheckTime > 0.5 {
            lastPresenceCheckTime = now
            
            // Score: Present=1.0, Distracted=0.5, Absent=0.0
            var score: Double = 0.0
            switch newState {
            case .absent: score = 0.0
            case .distracted: score = 0.5
            default: score = 1.0
            }
            presenceScores.append(score)
            
            // Log significant state changes
            if let lastEvent = events.last {
                if lastEvent.type != newState {
                    events.append(VisualEvent(timestamp: now, type: newState, description: getDescription(for: newState)))
                }
            } else {
                events.append(VisualEvent(timestamp: now, type: newState, description: getDescription(for: newState)))
            }
        }
    }
    
    private func getDescription(for state: PresenceState) -> String {
        switch state {
        case .present: return "Face detected"
        case .absent: return "Face not visible"
        case .distracted: return "Looking away"
        case .unsettled: return "Moving too much"
        case .grounded: return "Steady presence"
        }
    }
}

extension VideoAnalyzer: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // Run Vision Request
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .leftMirrored, options: [:])
        
        do {
            if let request = faceLandmarksRequest {
                try handler.perform([request])
            }
        } catch {
            print("Vision request failed: \(error)")
        }
    }
}
