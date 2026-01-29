import Foundation

enum PresenceState: String, Codable {
    case present = "Present"
    case absent = "Absent"
    case distracted = "Distracted" // Looking away
    case unsettled = "Unsettled" // Too much movement/posture shift
    case grounded = "Grounded" // Stable presence
}

struct VisualEvent: Codable, Identifiable {
    let id: UUID
    let timestamp: TimeInterval
    let type: PresenceState
    let description: String
    
    init(id: UUID = UUID(), timestamp: TimeInterval, type: PresenceState, description: String) {
        self.id = id
        self.timestamp = timestamp
        self.type = type
        self.description = description
    }
}

struct VideoAnalysisResult: Codable {
    let events: [VisualEvent]
    let presenceScore: Double // 0.0 - 1.0 (How detection/grounded they were)
    let gazeStabilityScore: Double // 0.0 - 1.0
}
