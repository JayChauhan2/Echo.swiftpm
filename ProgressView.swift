import SwiftUI
import Charts // Try using Charts framework, or fallback to Path if unavailable in swiftpm

struct ProgressView: View {
    @StateObject var viewModel: ProgressViewModel
    
    init(storage: RecordingStorage) {
        _viewModel = StateObject(wrappedValue: ProgressViewModel(storage: storage))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 5) {
                    Text("Your Progress 🚀")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(.red)
                    
                    Text("Practice, reflection, and growth over time")
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
                        Text("Words practiced total: \(viewModel.wordsPracticed)")
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

// MARK: - Box 1: Practice Goal (Semi Circle)
struct PracticeGoalBox: View {
    let minutes: Int
    let goal: Int
    
    var progress: Double {
        return min(Double(minutes) / Double(goal), 1.0)
    }
    
    var body: some View {
        VStack {
            HStack {
                Text("Daily Goal")
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
                    .trim(from: 0.0, to: 0.5 * progress)
                    .stroke(
                        LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .rotationEffect(.degrees(180))
                    .animation(.easeOut(duration: 1.0), value: progress)
                
                VStack(spacing: 2) {
                    Text("\(minutes) / \(goal)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                    Text("min today")
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
                .offset(y: -10)
            }
            .frame(height: 100) // Constrain height for semi-circle aspect
            .offset(y: 20) // Push down slightly to align
            
            Spacer()
        }
        .padding()
        .background(Color.white.opacity(0.12))
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

// MARK: - Box 2: Confidence Snapshot
struct ConfidenceSnapshotBox: View {
    let score: Int
    let currentChange: Int
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Confidence")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.8))
                Spacer()
                Image(systemName: "sparkles")
                    .foregroundStyle(.green)
            }
            
            Spacer()
            
            Text("\(score)%")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            
            HStack(spacing: 4) {
                if currentChange >= 0 {
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                    Text("\(currentChange)% this week")
                        .font(.caption)
                } else {
                    // Don't show negative red states, show "Steady" or neutral
                     Text("consistent")
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
    }
}

// MARK: - Box 3: Confidence Chart
struct ConfidenceChartBox: View {
    let trend: [Double]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Confidence Over Time")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.8))
            
            if trend.isEmpty {
                Spacer()
                Text("Start recording to see your growth")
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
                    .stroke(
                        LinearGradient(colors: [.yellow, .orange], startPoint: .leading, endPoint: .trailing),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
                    )
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
    }
}

// MARK: - Box 4: Clarity
struct ClarityBox: View {
    let score: Int
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Clarity")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.8))
                Spacer()
                Image(systemName: "mic.badge.plus") // Symbol for clear mic
                    .foregroundStyle(.purple)
            }
            
            Spacer()
            
            // Simple Bar
            VStack(alignment: .leading, spacing: 5) {
                Text("\(score)%")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                
                Text(score > 80 ? "Crystal clear" : "Good effort")
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
    }
}

// MARK: - Box 5: Hesitation
struct HesitationBox: View {
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
            
            Text("Flow state")
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
    }
}
