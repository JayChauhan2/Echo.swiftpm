import SwiftUI
import Charts // Try using Charts framework, or fallback to Path if unavailable in swiftpm

struct ProgressView: View {
    @EnvironmentObject var languageManager: LanguageManager
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @StateObject var viewModel: ProgressViewModel
    
    init(storage: RecordingStorage) {
        _viewModel = StateObject(wrappedValue: ProgressViewModel(storage: storage))
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                // Bento Grid
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 16),
                    GridItem(.flexible(), spacing: 16)
                ], spacing: 16) {
                    // Practice Goal
                    PracticeGoalBox(minutes: viewModel.practiceMinutesToday, goal: viewModel.practiceGoalMinutes)
                        .frame(minHeight: 180)
                    
                    // Confidence Snapshot
                    ConfidenceSnapshotBox(score: viewModel.currentConfidence, currentChange: viewModel.confidenceChange)
                        .frame(minHeight: 180)
                    
                    // Confidence Chart (Full Width Span)
                    ConfidenceChartBox(trend: viewModel.confidenceTrend)
                        .frame(minHeight: 220)
                        .gridCellColumns(2)
                    
                    // Clarity
                    ClarityBox(score: viewModel.clarityScore, status: viewModel.clarityStatus)
                        .frame(minHeight: 160)
                    
                    // Hesitation
                    HesitationBox(status: viewModel.hesitationScore)
                        .frame(minHeight: 160)
                }
                .padding(.horizontal)
                
                // Optional: Words Practiced
                HStack {
                    Text("\(languageManager.t("Words practiced total")): \(viewModel.wordsPracticed)")
                        .font(.caption)
                        .foregroundStyle(Color.secondary)
                }
                .padding(.top)
                .padding(.bottom, 40)
            }
            .navigationTitle(languageManager.t("Progress"))
            .background(Theme.background)
            .onAppear {
                viewModel.recalculateMetrics()
            }
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
                    .foregroundStyle(Theme.secondaryLabel)
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
                        .foregroundStyle(Theme.primaryLabel)
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
        .background(Theme.secondaryBackground)
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Theme.tertiaryBackground, lineWidth: 1)
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
                    .foregroundStyle(Theme.secondaryLabel)
                Spacer()
                Image(systemName: "sparkles")
                    .foregroundStyle(.green)
            }
            
            Spacer()
            
            AnimatableNumberText(value: animatedScore, suffix: "%")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.primaryLabel)
            
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
        .background(Theme.secondaryBackground)
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Theme.tertiaryBackground, lineWidth: 1)
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
                .foregroundStyle(Theme.secondaryLabel)
            
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
        .background(Theme.secondaryBackground)
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Theme.tertiaryBackground, lineWidth: 1)
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
    let score: Int?
    let status: String
    @State private var animatedScore: Double = 0
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(languageManager.t("Clarity"))
                    .font(.headline)
                    .foregroundStyle(Theme.secondaryLabel)
                Spacer()
                Image(systemName: "mic.badge.plus") // Symbol for clear mic
                    .foregroundStyle(.purple)
            }
            
            Spacer()
            
            // Simple Bar
            VStack(alignment: .leading, spacing: 5) {
                if let score = score {
                    AnimatableNumberText(value: animatedScore, suffix: "%")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(Theme.primaryLabel)
                } else {
                    Text("--%")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(Theme.secondaryLabel)
                }
                
                Text(status)
                    .font(.caption)
                    .foregroundStyle(.gray)
                
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.gray.opacity(0.3))
                        Capsule()
                            .fill(Color.purple)
                            .frame(width: geo.size.width * (CGFloat(score ?? 0) / 100.0))
                    }
                }
                .frame(height: 8)
            }
            
            Spacer()
        }
        .padding()
        .background(Theme.secondaryBackground)
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Theme.tertiaryBackground, lineWidth: 1)
        )
        .onAppear {
            if let score = score {
                withAnimation(.easeOut(duration: 1.5)) {
                    animatedScore = Double(score)
                }
            }
        }
        // Accessibility
        .accessibilityElement(children: .combine)
        .accessibilityLabel(languageManager.t("Clarity Score"))
        .accessibilityValue(score != nil ? "\(score!) \(languageManager.t("percent")). \(status)" : status)
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
                    .foregroundStyle(Theme.secondaryLabel)
                Spacer()
                Image(systemName: "waveform.path.ecg")
                    .foregroundStyle(.orange)
            }
            
            Spacer()
            
            Text(status)
                .font(.title3) // Smaller font to fit text
                .fontWeight(.bold)
                .foregroundStyle(Theme.primaryLabel)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
            
            Text(languageManager.t("Flow state"))
               .font(.caption)
               .foregroundStyle(.gray)
            
            Spacer()
        }
        .padding()
        .background(Theme.secondaryBackground)
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Theme.tertiaryBackground, lineWidth: 1)
        )
        // Accessibility
        .accessibilityElement(children: .combine)
        .accessibilityLabel(languageManager.t("Hesitation Status"))
        .accessibilityValue(status)
    }
}
