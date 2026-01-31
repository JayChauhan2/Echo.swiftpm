import SwiftUI
import Charts // Try using Charts framework, or fallback to Path if unavailable in swiftpm

struct ProgressView: View {
    @StateObject var viewModel: ProgressViewModel
    @EnvironmentObject var languageManager: LanguageManager
    
    init(storage: RecordingStorage) {
        _viewModel = StateObject(wrappedValue: ProgressViewModel(storage: storage))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 5) {
                    Text(languageManager.t("Your Progress 🚀"))
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(.red)
                    
                    Text(languageManager.t("Practice, reflection, and growth over time"))
                        .font(.body)
                        .foregroundStyle(.gray)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.top, 20)
                
                // Bento Grid
                VStack(spacing: 16) {
                    // Top Row: Practice Goal (Hero) + Confidence Snapshot
                    HStack(spacing: 16) {
                        // Box 1: Practice Goal (Blue/Purple theme)
                        PracticeGoalBox(minutes: viewModel.practiceMinutesToday, goal: viewModel.practiceGoalMinutes)
                            .frame(maxWidth: .infinity)
                            .frame(height: 180)
                        
                        // Box 2: Confidence Snapshot (Green theme)
                        ConfidenceSnapshotBox(score: viewModel.currentConfidence, currentChange: viewModel.confidenceChange)
                            .frame(maxWidth: .infinity)
                            .frame(height: 180)
                    }
                    
                    // Box 3: Confidence Chart (Full Width)
                    ConfidenceChartBox(trend: viewModel.confidenceTrend)
                        .frame(height: 220)
                    
                    // Bottom Row: Clarity + Hesitation
                    HStack(spacing: 16) {
                        // Box 4: Clarity (Purple theme)
                        ClarityBox(score: viewModel.clarityScore)
                            .frame(maxWidth: .infinity)
                            .frame(height: 160)
                        
                        // Box 5: Hesitation (Orange theme)
                        HesitationBox(status: viewModel.hesitationScore)
                            .frame(maxWidth: .infinity)
                            .frame(height: 160)
                    }
                    
                    // Optional: Words Practiced
                    HStack {
                        Text("\(languageManager.t("Words practiced total")): \(viewModel.wordsPracticed)")
                            .font(.caption)
                            .foregroundStyle(.gray)
                    }
                    .padding(.top)
                }
                .padding(.horizontal)
                .padding(.bottom, 40)
            }
        }
        .background(Color.black.ignoresSafeArea())
        .onAppear {
            viewModel.recalculateMetrics()
        }
    }
}

struct PracticeGoalBox: View {
    @EnvironmentObject var languageManager: LanguageManager
    let minutes: Int
    let goal: Int
    
    @State private var animatedProgress: CGFloat = 0.0
    
    var progress: Double {
        return min(Double(minutes) / Double(goal), 1.0)
    }
    
    var body: some View {
        VStack {
            HStack {
                Text(languageManager.t("Daily Goal"))
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.8))
                Spacer()
                Image(systemName: "hourglass")
                    .foregroundStyle(.blue)
            }
            .padding(.bottom, 10)
            
            ZStack {
                // Background Track
                Circle()
                    .trim(from: 0.0, to: 0.5)
                    .stroke(Color.gray.opacity(0.3), style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .rotationEffect(.degrees(180))
                
                // Progress Track
                Circle()
                    .trim(from: 0.0, to: 0.5 * animatedProgress)
                    .stroke(
                        LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .rotationEffect(.degrees(180))
                
                VStack(spacing: 2) {
                    Text("\(minutes) / \(goal)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                    Text(languageManager.t("min today"))
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
                .offset(y: -10)
            }
            .frame(height: 100)
            .offset(y: 20)
            .onAppear {
                withAnimation(.easeOut(duration: 1.5)) {
                    animatedProgress = progress
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color.white.opacity(0.12))
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        // Accessibility
        .accessibilityElement(children: .combine)
        .accessibilityLabel(languageManager.t("Daily Practice Goal"))
        .accessibilityValue("\(minutes) \(languageManager.t("out of")) \(goal) \(languageManager.t("minutes completed"))")
    }
}

struct ConfidenceSnapshotBox: View {
    @EnvironmentObject var languageManager: LanguageManager
    let score: Int
    let currentChange: Int
    
    @State private var animatedScore: Double = 0
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(languageManager.t("Confidence"))
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.8))
                Spacer()
                Image(systemName: "sparkles")
                    .foregroundStyle(.green)
            }
            
            Spacer()
            
            AnimatableNumberText(value: animatedScore, suffix: "%")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            
            HStack(spacing: 4) {
                if currentChange >= 0 {
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                    Text("\(currentChange)% \(languageManager.t("this week"))")
                        .font(.caption)
                } else {
                     Text(languageManager.t("consistent"))
                        .font(.caption)
                }
            }
            .foregroundStyle(.green)
            
            Spacer()
        }
        .padding()
        .background(Color.white.opacity(0.12))
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .onAppear {
            withAnimation(.easeOut(duration: 2.0)) {
                animatedScore = Double(score)
            }
        }
        // Accessibility
        .accessibilityElement(children: .combine)
        .accessibilityLabel(languageManager.t("Confidence Score"))
        .accessibilityValue("\(score) \(languageManager.t("percent")). \(currentChange >= 0 ? "\(languageManager.t("Up")) \(currentChange)\(languageManager.t("percent this week"))" : languageManager.t("Consistent this week"))")
    }
}

// MARK: - Helper: Animatable Number Text
struct AnimatableNumberText: View, Animatable {
    var value: Double
    var suffix: String
    
    var animatableData: Double {
        get { value }
        set { value = newValue }
    }
    
    var body: some View {
        Text("\(Int(value))\(suffix)")
    }
}

// MARK: - Box 3: Confidence Chart
struct ConfidenceChartBox: View {
    @EnvironmentObject var languageManager: LanguageManager
    let trend: [Double]
    @State private var drawProgress: CGFloat = 0.0
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(languageManager.t("Confidence Over Time"))
                .font(.headline)
                .foregroundStyle(.white.opacity(0.8))
            
            if trend.isEmpty {
                Spacer()
                Text(languageManager.t("Start recording to see your growth"))
                    .font(.subheadline)
                    .foregroundStyle(.gray)
                    .frame(maxWidth: .infinity)
                Spacer()
            } else {
                GeometryReader { geo in
                    Path { path in
                        let width = geo.size.width
                        let height = geo.size.height
                        
                        // Normalize data
                        // Assuming confidence is 0.0 to 1.0. Map to height.
                        let stepX = width / CGFloat(max(trend.count - 1, 1))
                        
                        for (index, value) in trend.enumerated() {
                            let x = stepX * CGFloat(index)
                            let y = height - (CGFloat(value) * height) // Invert Y
                            
                            if index == 0 {
                                path.move(to: CGPoint(x: x, y: y))
                            } else {
                                // Simple line for now, could be smooth bezier
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                    }
                    .trim(from: 0, to: drawProgress) // Animate from 0 to 1
                    .stroke(
                        LinearGradient(colors: [.yellow, .orange], startPoint: .leading, endPoint: .trailing),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
                    )
                    .onAppear {
                        withAnimation(.easeOut(duration: 2.0)) {
                            drawProgress = 1.0
                        }
                    }
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 4)
            }
        }
        .padding()
        .background(Color.white.opacity(0.12))
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        // Accessibility
        .accessibilityElement(children: .combine)
        .accessibilityLabel(languageManager.t("Confidence Trend Chart"))
        .accessibilityValue(trend.isEmpty ? languageManager.t("No data yet") : languageManager.t("Graph showing user confidence over the last few sessions"))
    }
}

// MARK: - Box 4: Clarity
struct ClarityBox: View {
    @EnvironmentObject var languageManager: LanguageManager
    let score: Int
    @State private var animatedScore: Double = 0
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(languageManager.t("Clarity"))
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.8))
                Spacer()
                Image(systemName: "mic.badge.plus") // Symbol for clear mic
                    .foregroundStyle(.purple)
            }
            
            Spacer()
            
            // Simple Bar
            VStack(alignment: .leading, spacing: 5) {
                AnimatableNumberText(value: animatedScore, suffix: "%")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                
                    .foregroundStyle(.white)
                
                Text(score > 80 ? languageManager.t("Crystal clear") : languageManager.t("Good effort"))
                    .font(.caption)
                    .foregroundStyle(.gray)
                
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.gray.opacity(0.3))
                        Capsule()
                            .fill(Color.purple)
                            .frame(width: geo.size.width * (CGFloat(score) / 100.0))
                    }
                }
                .frame(height: 8)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.white.opacity(0.12))
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .onAppear {
            withAnimation(.easeOut(duration: 1.5)) {
                animatedScore = Double(score)
            }
        }
        // Accessibility
        .accessibilityElement(children: .combine)
        .accessibilityLabel(languageManager.t("Clarity Score"))
        .accessibilityValue("\(score) \(languageManager.t("percent")). \(score > 80 ? languageManager.t("Crystal clear") : languageManager.t("Good effort"))")
    }
}

// MARK: - Box 5: Hesitation
struct HesitationBox: View {
    @EnvironmentObject var languageManager: LanguageManager
    let status: String
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Hesitation")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.8))
                Spacer()
                Image(systemName: "waveform.path.ecg")
                    .foregroundStyle(.orange)
            }
            
            Spacer()
            
            Text(status)
                .font(.title3) // Smaller font to fit text
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
            
            Text(languageManager.t("Flow state"))
               .font(.caption)
               .foregroundStyle(.gray)
            
            Spacer()
        }
        .padding()
        .background(Color.white.opacity(0.12))
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        // Accessibility
        .accessibilityElement(children: .combine)
        .accessibilityLabel(languageManager.t("Hesitation Status"))
        .accessibilityValue(status)
    }
}
