import Foundation
import SwiftUI

class ProgressViewModel: ObservableObject {
    @Published var practiceMinutesToday: Int = 0
    @AppStorage("practiceGoalMinutes") var practiceGoalMinutes: Int = 10
    @Published var confidenceTrend: [Double] = []
    @Published var currentConfidence: Int = 0
    @Published var confidenceChange: Int = 0 // Percentage change
    @Published var clarityScore: Int? = nil
    @Published var clarityStatus: String = LanguageManager.shared.t("No analysis yet")
    @Published var hesitationScore: String = LanguageManager.shared.t("Stable") // "↓ 12%", "Stable", etc.
    @Published var wordsPracticed: Int = 0
    @Published var wordCountChange: Int = 0
    
    private var storage: RecordingStorage
    
    init(storage: RecordingStorage) {
        self.storage = storage
        // Observe changes in storage to update metrics
        // For simplicity in this context, we will manually recalculate when view appears or storage changes
        recalculateMetrics()
    }
    
    func recalculateMetrics() {
        let recordings = storage.recordings
        
        // 1. Practice Consistency (Today)
        let today = Calendar.current.startOfDay(for: Date())
        let todayRecordings = recordings.filter { Calendar.current.isDateInToday($0.date) }
        let totalDuration = todayRecordings.reduce(0) { $0 + $1.duration }
        practiceMinutesToday = Int(round(totalDuration / 60.0))
        
        // 2. Confidence Trend & Snapshot
        // Get valid confidence scores (0.0 to 1.0) sorted by date
        let sortedRecordings = recordings.sorted { $0.date < $1.date }
        let confidenceScores = sortedRecordings.compactMap { $0.analysis?.confidenceScore }
        
        // Trend for chart (last 10 sessions)
        confidenceTrend = Array(confidenceScores.suffix(10))
        
        // Current Confidence
        if let lastScore = confidenceScores.last {
            currentConfidence = Int(lastScore * 100)
        } else {
            currentConfidence = 0
        }
        
        // Confidence Change (Vs Last Week avg or just last few?)
        // Let's compare this week vs last week if enough data, or just last 3 vs prev 3.
        // Simple fallback: Compare last vs avg of others.
        if confidenceScores.count >= 2 {
            let recent = confidenceScores.last!
            let previous = confidenceScores.dropLast().last! 
            // Better: Avg of last 3 vs Avg of prev 3?
            // Let's keep it simple: Compare last session to average of all previous
            let others = confidenceScores.dropLast()
            let avgPrevious = others.reduce(0, +) / Double(others.count)
            let diff = recent - avgPrevious
            confidenceChange = Int(diff * 100)
        } else {
            confidenceChange = 0
        }
        
        // 3. Clarity
        // Derived from: High Volume Stability + Low Pauses
        // Let's create a synthetic "Clarity" score from 0-100
        // Fix: Find the MOST RECENT valid audio analysis, even if it's not the last recording
        if let lastAnalysis = sortedRecordings.reversed().compactMap({ $0.analysis }).first {
            // Pause Frequency: normal is ~0-10 pauses/min. High is > 15.
            // Stability: 1.0 is stable.
            
            let stability = lastAnalysis.volumeStability // 0..1
            
            // Normalize pause freq: 0 pauses -> 1.0, 20 pauses -> 0.0
            let pauseScore = max(0.0, 1.0 - (lastAnalysis.pauseFrequency / 20.0))
            
            let rawClarity = (stability * 0.4) + (pauseScore * 0.6) // Weight pauses more
            let score = Int(rawClarity * 100)
            clarityScore = score
            clarityStatus = score > 80 ? LanguageManager.shared.t("Crystal clear") : LanguageManager.shared.t("Good effort")
        } else {
            clarityScore = nil
            clarityStatus = LanguageManager.shared.t("No analysis yet")
        }
        
        // 4. Hesitation
        // Metric: Pauses per minute. Compare average of "This Week"
        let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        let thisWeekRecordings = recordings.filter { $0.date >= oneWeekAgo }
        
        if !thisWeekRecordings.isEmpty {
            let validAnalyses = thisWeekRecordings.compactMap { $0.analysis }
            if !validAnalyses.isEmpty {
                let avgPauses = validAnalyses.reduce(0) { $0 + $1.pauseFrequency } / Double(validAnalyses.count)
                // Interpretation
                // Compare to "life time" avg or just display value?
                // User wants "Hesitations ↓ 12% this week". Need "Last Week" data.
                // Fallback if no last week: just show current level.
                
                // Let's mock a comparison if we don't have history, or just show "Low" / "Medium"
                // Actually, let's try to calculate change if we have enough data.
                let prevWeekRecordings = recordings.filter { $0.date < oneWeekAgo && $0.date >= Calendar.current.date(byAdding: .day, value: -14, to: Date())! }
                
                if !prevWeekRecordings.isEmpty {
                    let prevAnalyses = prevWeekRecordings.compactMap { $0.analysis }
                    let prevAvg = prevAnalyses.reduce(0) { $0 + $1.pauseFrequency } / Double(prevAnalyses.count)
                    
                    if prevAvg > 0 {
                        let improvement = (prevAvg - avgPauses) / prevAvg
                        // Positive improvement means FEWER pauses
                        let percent = Int(improvement * 100)
                        if percent > 0 {
                            hesitationScore = "↓ \(percent)% \(LanguageManager.shared.t("this week"))"
                        } else if percent < 0 {
                            hesitationScore = "↑ \(abs(percent))% \(LanguageManager.shared.t("this week"))"
                        } else {
                            hesitationScore = "\(LanguageManager.shared.t("Stable")) \(LanguageManager.shared.t("this week"))"
                        }
                    } else {
                        hesitationScore = LanguageManager.shared.t("Analyzing...")
                    }
                } else {
                    // No previous week data
                    if avgPauses < 5 {
                        hesitationScore = LanguageManager.shared.t("Very few pauses")
                    } else if avgPauses < 12 {
                        hesitationScore = LanguageManager.shared.t("Normal flow")
                    } else {
                        hesitationScore = LanguageManager.shared.t("High pauses")
                    }
                }
            } else {
                hesitationScore = LanguageManager.shared.t("No analysis yet")
            }
        } else {
            hesitationScore = LanguageManager.shared.t("No data this week")
        }
        
        // 5. Words Practiced
        wordsPracticed = recordings.reduce(0) { $0 + ($1.analysis?.transcription.split(separator: " ").count ?? 0) }
    }
}
