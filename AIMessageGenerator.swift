import Foundation

/// AI Message Generator for personalized onboarding messages
/// 
/// CURRENT IMPLEMENTATION: Rule-based message generation
/// FUTURE ENHANCEMENT: Integrate on-device LLM for dynamic message generation
/// 
/// For offline functionality, this should use an on-device language model such as:
/// - Apple's MLX framework with a quantized LLM
/// - Core ML with a converted language model
/// - Swift Transformers library
/// 
/// The on-device model would generate personalized messages based on:
/// - User's practice history and patterns
/// - Current confidence trends
/// - Time of day and session frequency
/// - Specific areas needing improvement
/// 
/// Example integration pattern:
/// ```swift
/// // Load on-device model (one-time initialization)
/// let model = try await MLModel(contentsOf: modelURL)
/// 
/// // Generate personalized message
/// let prompt = "Generate an encouraging message for a user with \(currentConfidence)% confidence..."
/// let response = try await model.prediction(from: prompt)
/// ```
class AIMessageGenerator {
    
    /// Generates a personalized message based on user's progress data
    static func generateMessage(
        isFirstLaunch: Bool,
        practiceMinutesToday: Int,
        practiceGoalMinutes: Int,
        currentConfidence: Int,
        confidenceChange: Int,
        totalRecordings: Int
    ) -> String {
        
        if isFirstLaunch {
            return LanguageManager.shared.t("Welcome to Echo! This app helps you improve your communication skills through voice and video analysis. Practice regularly, track your progress, and watch your confidence grow.")
        }
        
        // Returning user - generate personalized message based on data
        
        // No recordings yet
        if totalRecordings == 0 {
            return LanguageManager.shared.t("Ready to start your journey? Record your first practice session and discover insights about your communication style.")
        }
        
        // Below practice goal
        if practiceMinutesToday < practiceGoalMinutes {
            let remaining = practiceGoalMinutes - practiceMinutesToday
            if remaining == practiceGoalMinutes {
                // No practice yet today
                let key = "Start your day strong! Complete %d minutes of practice to reach your daily goal."
                let format = LanguageManager.shared.t(key)
                return String(format: format, practiceGoalMinutes)
            } else {
                // Some practice done, but not at goal yet
                let key = "You're making progress! Just %d more minutes to reach your daily goal of %d minutes."
                let format = LanguageManager.shared.t(key)
                return String(format: format, remaining, practiceGoalMinutes)
            }
        }
        
        // Confidence trending down
        if confidenceChange < -5 {
            return LanguageManager.shared.t("Keep going! Consistency is key. Try focusing on speaking slowly and clearly in your next session.")
        }
        
        // Confidence improving
        if confidenceChange > 5 {
            return LanguageManager.shared.t("Excellent work! Your confidence is improving. Consider increasing your practice goal to challenge yourself further.")
        }
        
        // Doing well overall
        if currentConfidence >= 70 && practiceMinutesToday >= practiceGoalMinutes {
            return LanguageManager.shared.t("You're doing great! Your confidence is strong and you've hit your daily goal. Keep up the amazing work!")
        }
        
        // Default encouraging message
        return LanguageManager.shared.t("Welcome back! Ready to continue improving your communication skills? Let's make today count.")
    }
}
