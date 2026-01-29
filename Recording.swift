import Foundation

struct Recording: Codable, Identifiable {
    let id: UUID
    let filename: String
    let date: Date
    let duration: TimeInterval
    let samples: [Float]
    var analysis: AudioAnalysisResult? // Make mutable to update after analysis
    var analysisError: String? // Store error reason if analysis fails
    
    // Video Support
    let isVideo: Bool
    var videoAnalysis: VideoAnalysisResult?
    
    init(id: UUID = UUID(), filename: String, date: Date, duration: TimeInterval, samples: [Float] = [], analysis: AudioAnalysisResult? = nil, analysisError: String? = nil, isVideo: Bool = false, videoAnalysis: VideoAnalysisResult? = nil) {
        self.id = id
        self.filename = filename
        self.date = date
        self.duration = duration
        self.samples = samples
        self.analysis = analysis
        self.analysisError = analysisError
        self.isVideo = isVideo
        self.videoAnalysis = videoAnalysis
    }
}
