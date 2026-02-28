import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var onboardingManager: OnboardingManager
    @EnvironmentObject var storage: RecordingStorage
    @EnvironmentObject var languageManager: LanguageManager
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var progressViewModel: ProgressViewModel
    
    @State private var contentOffset: CGFloat = 0
    
    init(storage: RecordingStorage) {
        _progressViewModel = StateObject(wrappedValue: ProgressViewModel(storage: storage))
    }
    
    var body: some View {
        ZStack {
            // Apple-style gradient background - adaptive to color scheme
            LinearGradient(
                gradient: Gradient(colors: colorScheme == .dark ? [
                    Color(uiColor: .systemBackground),
                    Color(uiColor: .secondarySystemBackground)
                ] : [
                    Color(red: 0.95, green: 0.95, blue: 1.0),  // Very soft lavender
                    Color(red: 0.94, green: 0.97, blue: 1.0)   // Very soft blue
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Scrollable content area
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 32) {
                        Spacer()
                            .frame(height: 60)
                        
                        // App Icon or Symbol
                        Image(systemName: "waveform.circle.fill")
                            .font(.system(size: 80))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Theme.tint, Theme.tint.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .accessibilityHidden(true)
                        
                        // Title
                        Text(onboardingManager.isFirstLaunch ? 
                             languageManager.t("Welcome to Echo") : 
                             languageManager.t("Welcome Back"))
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                            .accessibilityAddTraits(.isHeader)
                        
                        // Personalized Message
                        Text(generatePersonalizedMessage())
                            .font(.system(size: 17, weight: .regular, design: .default))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                            .padding(.horizontal, 32)
                            .accessibilityLabel(generatePersonalizedMessage())
                            .accessibilityAddTraits(.isStaticText)
                        
                        if onboardingManager.isFirstLaunch {
                            // First-time feature highlights
                            VStack(spacing: 24) {
                                FeatureRow(
                                    icon: "mic.fill",
                                    title: languageManager.t("Voice Recording"),
                                    description: languageManager.t("Record and analyze your voice for clarity and confidence")
                                )
                                
                                FeatureRow(
                                    icon: "video.fill",
                                    title: languageManager.t("Video Analysis"),
                                    description: languageManager.t("Capture your presence and body language")
                                )
                                
                                FeatureRow(
                                    icon: "chart.bar.fill",
                                    title: languageManager.t("Track Progress"),
                                    description: languageManager.t("Monitor your improvement over time")
                                )
                                
                                FeatureRow(
                                    icon: "sparkles",
                                    title: languageManager.t("AI Insights"),
                                    description: languageManager.t("Get personalized feedback and suggestions")
                                )
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 16)
                        } else {
                            // Returning user motivation (Commercial/Pro style)
                            VStack(spacing: 24) {
                                FeatureRow(
                                    icon: "waveform.path.ecg",
                                    title: languageManager.t("Level Up Your Voice"),
                                    description: languageManager.t("Continue practicing to unlock your full vocal potential")
                                )
                                
                                FeatureRow(
                                    icon: "brain.head.profile",
                                    title: languageManager.t("Smart Analysis"),
                                    description: languageManager.t("Did you know Echo spots filler words like 'um' and 'ah' to help you sound pro?")
                                )
                                
                                FeatureRow(
                                    icon: "chart.line.uptrend.xyaxis",
                                    title: languageManager.t("Measure Your Impact"),
                                    description: languageManager.t("See exactly how confident you appear with advanced AI analysis")
                                )
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 16)
                        }
                        
                        Spacer()
                            .frame(height: 120) // Space for button
                    }
                    .padding(.horizontal, 20)
                }
                
                // Bottom button area with blur background (Apple style)
                VStack(spacing: 0) {
                    // Subtle divider
                    Rectangle()
                        .fill(Color.primary.opacity(0.1))
                        .frame(height: 0.5)
                    
                    // Button container
                    Button(action: {
                        HapticManager.shared.medium()
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            onboardingManager.dismissOnboarding()
                        }
                    }) {
                        Text(languageManager.t("I'm Ready!"))
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(Theme.tint)
                            )
                            .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 8)
                    .accessibilityLabel(languageManager.t("I'm Ready! Dismiss onboarding"))
                    .accessibilityHint(languageManager.t("Double tap to start using Echo"))
                }
                .background(.ultraThinMaterial)
            }
        }
        .onAppear {
            progressViewModel.recalculateMetrics()
        }
    }
    
    private func generatePersonalizedMessage() -> String {
        return AIMessageGenerator.generateMessage(
            isFirstLaunch: onboardingManager.isFirstLaunch,
            practiceMinutesToday: progressViewModel.practiceMinutesToday,
            practiceGoalMinutes: progressViewModel.practiceGoalMinutes,
            currentConfidence: progressViewModel.currentConfidence,
            confidenceChange: progressViewModel.confidenceChange,
            totalRecordings: storage.recordings.count
        )
    }
}

// MARK: - Feature Row Component
struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Icon container
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Theme.tint.opacity(0.15))
                    .frame(width: 48, height: 48)
                
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(Theme.tint)
            }
            .accessibilityHidden(true)
            
            // Text content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold, design: .default))
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.system(size: 15, weight: .regular, design: .default))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(description)")
    }
}
