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
        currentPresence = .absent
    }
    
    func startAnalysis() {
        cleanUp()
        recordingStartTime = Date()
    }
    
    func stopAnalysis() -> VideoAnalysisResult {
        // Calculate final scores
        let avgPresence = presenceScores.isEmpty ? 0.0 : presenceScores.reduce(0, +) / Double(presenceScores.count)
        // Simplified Gaze Stability (mock calculation based on events count for now)
        let distractedCount = events.filter { $0.type == .distracted }.count
        let stability = max(0.0, 1.0 - (Double(distractedCount) * 0.1))
        
        return VideoAnalysisResult(
            events: events,
            presenceScore: avgPresence,
            gazeStabilityScore: stability
        )
    }
    
    private func handleFaceLandmarks(request: VNRequest, error: Error?) {
        guard let results = request.results as? [VNFaceObservation], let result = results.first else {
            // No face found
            updatePresence(.absent)
            return
        }
        
        // Face found
        // Analyze Gaze / Pose
        if let landmarks = result.landmarks {
            // Simple heuristic: Face yaw/roll or eye positions
            // Vision doesn't give direct gaze, but we can detect if face is turned away
            // result.yaw is available in newer iOS, or use landmarks
            
            if let yaw = result.yaw {
                let yawVal = abs(yaw.doubleValue)
                if yawVal > 0.5 { // Significant turn
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
        DispatchQueue.main.async {
            self.currentPresence = newState
        }
        
        guard let startTime = recordingStartTime else { return }
        let now = Date().timeIntervalSince(startTime)
        
        // Rate limit events
        if now - lastPresenceCheckTime > 0.5 {
            lastPresenceCheckTime = now
            presenceScores.append(newState == .absent ? 0.0 : 1.0)
            
            // Log significant state changes or periodic updates?
            // Let's log state changes for now
            if let lastEvent = events.last, lastEvent.type != newState {
                let description = getDescription(for: newState)
                events.append(VisualEvent(timestamp: now, type: newState, description: description))
            } else if events.isEmpty {
                let description = getDescription(for: newState)
                events.append(VisualEvent(timestamp: now, type: newState, description: description))
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
