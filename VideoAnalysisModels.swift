import Foundation

enum PresenceState: String, Codable {
    case present = "Present"
    case absent = "Absent"
    case distracted = "Distracted" // Looking away
    case unsettled = "Unsettled" // Too much movement/posture shift
    case grounded = "Grounded" // Stable presence
    // New granular states for UI
    case smiling = "Smiling"
    case fidgeting = "Fidgeting"
    case poorFraming = "Poorly Framed"
}

struct VisualEvent: Codable, Identifiable {
    let id: UUID
    let timestamp: TimeInterval
    let type: PresenceState
    let description: String
    
    // UI Metadata
    var isPositive: Bool {
        return type == .grounded || type == .smiling || type == .present
    }
    
    init(id: UUID = UUID(), timestamp: TimeInterval, type: PresenceState, description: String) {
        self.id = id
        self.timestamp = timestamp
        self.type = type
        self.description = description
    }
}

// MARK: - New Granular Metrics

struct HeadMovementMetrics: Codable {
    let averageVelocity: Double
    let stillnessScore: Double // 0-1
    let fidgetIntervals: [TimeInterval] // Timestamps of high movement
}

struct GazeMetrics: Codable {
    let eyeContactDuration: TimeInterval
    let engagementRatio: Double // Time looking at camera / total time
    let longestStreak: TimeInterval
}

struct ExpressionMetrics: Codable {
    let energyScore: Double // Variance of expressions
    let smileCount: Int
    let smileTimestamps: [TimeInterval]
}

struct FramingMetrics: Codable {
    let averageFaceRatio: Double // Face area / Screen area
    let isCenteredScore: Double // 0-1
    let postureIssueDetected: Bool
}

struct VideoAnalysisResult: Codable {
    let events: [VisualEvent]
    let presenceScore: Double // 0.0 - 1.0
    
    // New Granular Data
    let movement: HeadMovementMetrics?
    let gaze: GazeMetrics?
    let expression: ExpressionMetrics?
    let framing: FramingMetrics?
    
    // Deprecated but kept for backward compatibility if needed, or computed property
    var gazeStabilityScore: Double {
        return gaze?.engagementRatio ?? 0.0
    }
    
    // Initializer for compatibility
    init(events: [VisualEvent], presenceScore: Double, movement: HeadMovementMetrics?, gaze: GazeMetrics?, expression: ExpressionMetrics?, framing: FramingMetrics?) {
        self.events = events
        self.presenceScore = presenceScore
        self.movement = movement
        self.gaze = gaze
        self.expression = expression
        self.framing = framing
    }
}

