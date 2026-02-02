import SwiftUI
import AVFoundation
import AVKit

struct PlaybackView: View {
    @ObservedObject var voiceRecorder: VoiceRecorder
    @ObservedObject var storage: RecordingStorage
    let recording: Recording
    
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var languageManager: LanguageManager
    @State private var showDeleteAlert = false
    
    var body: some View {
        Group {
            if recording.isVideo {
                VideoPlaybackView(recording: recording, storage: storage)
            } else {
                AudioPlaybackView(voiceRecorder: voiceRecorder, storage: storage, recording: recording)
            }
        }

        .navigationTitle(getRecordingName())
        .navigationBarTitleDisplayMode(.inline)
        .background(Theme.background)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    HapticManager.shared.warning() // Warning haptic for delete
                    showDeleteAlert = true
                }) {
                    Image(systemName: "trash")
                    .foregroundColor(.red)
                }
            }
        }
        .alert(languageManager.t("Delete Recording"), isPresented: $showDeleteAlert) {
            Button(languageManager.t("Cancel"), role: .cancel) { 
                HapticManager.shared.light() // Light haptic for cancel
            }
            Button(languageManager.t("Delete"), role: .destructive) {
                HapticManager.shared.error() // Error haptic for deletion
                storage.deleteRecording(recording)
                dismiss()
            }
        } message: {
            Text("\(languageManager.t("Are you sure you want to delete")) \"\(getRecordingName())\"?")
        }
    }
    
    func getRecordingName() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a" // e.g., "Jan 29, 2:30 PM"
        return formatter.string(from: recording.date)
    }
}

// MARK: - Video Playback View

struct VideoPlaybackView: View {
    let recording: Recording
    @ObservedObject var storage: RecordingStorage
    
    @State private var player: AVPlayer?
    @State private var currentTime: TimeInterval = 0
    @State private var isPlaying = false
    @State private var activeEvent: VisualEvent?
    
    // Timer for updating UI
    let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ScrollView {
            VStack {
            // Video Player
            ZStack(alignment: .bottom) {
                if let player = player {
                    VideoPlayer(player: player)
                        .aspectRatio(9/16, contentMode: .fit) // Vertical video aspect
                        .cornerRadius(12)
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .aspectRatio(9/16, contentMode: .fit)
                        .cornerRadius(12)
                        .overlay(SwiftUI.ProgressView())
                }
                
                // Overlay for Active Event
                // We show this ON TOP of the video
                if let event = activeEvent {
                    Text(event.description)
                        .font(.headline)
                        .padding(8)
                        .background(getPresenceColor(event.type).opacity(0.8))
                        .cornerRadius(8)
                        .foregroundStyle(.white)
                        .padding(.bottom, 40)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .frame(maxHeight: 550)
            
            // Smart Timeline
            VStack(alignment: .leading, spacing: 8) {
                Text("Analysis Timeline")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.gray)
                    .padding(.horizontal)
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Theme.secondaryBackground)
                        
                        VStack(spacing: 2) {
                            // Lane 1: Audio Confidence (Green/Orange)
                            if let audio = recording.analysis {
                                TimelineLane(duration: recording.duration, segments: audio.segments, colorMap: { state in
                                    switch state {
                                    case .confident: return .green
                                    case .hesitant: return .orange
                                    default: return .gray.opacity(0.3)
                                    }
                                })
                            }
                            
                            // Lane 2: Gaze (Blue/Clear)
                            if let video = recording.videoAnalysis {
                                TimelineLane(duration: recording.duration, events: video.events.filter { $0.type == .distracted }, baseColor: .red)
                            }
                            
                            // Lane 3: Movement (Yellow/Clear)
                            if let video = recording.videoAnalysis {
                                TimelineLane(duration: recording.duration, events: video.events.filter { $0.type == .fidgeting }, baseColor: .yellow)
                            }
                        }
                        .padding(.vertical, 4)
                        
                        // Playhead
                        Rectangle()
                            .fill(Theme.primaryLabel)
                            .frame(width: 2)
                            .padding(.vertical, -4) // EXTEND past lanes
                            .position(x: CGFloat(currentTime / recording.duration) * geometry.size.width, y: 15) // Approximate center
                    }
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let fraction = value.location.x / geometry.size.width
                                let time = Double(max(0, min(1, fraction))) * recording.duration
                                player?.seek(to: CMTime(seconds: time, preferredTimescale: 600))
                                currentTime = time
                            }
                    )
                }
                .frame(height: 40) // Taller for lanes
                .padding(.horizontal)
            }
            .padding(.top, 10)
            
            // Insight Cards (Cross-Modal)
            if let video = recording.videoAnalysis, let audio = recording.analysis {
                let crossModalInsights = generateCrossModalInsights(video: video, audio: audio)
                if !crossModalInsights.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(crossModalInsights, id: \.self) { insight in
                                HStack {
                                    Image(systemName: "lightbulb.fill")
                                        .foregroundStyle(.yellow)
                                    Text(insight)
                                        .font(.caption)
                                        .foregroundStyle(Theme.primaryLabel)
                                }
                                .padding(8)
                                .background(Theme.tertiaryBackground)
                                .cornerRadius(8)
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 8)
                }
            }
            
            // Speed Control & Analysis Summary
            VStack {
                 HStack {
                     Text("Playback Speed")
                         .font(.caption)
                         .foregroundStyle(.gray)
                     Spacer()
                     Menu {
                         Button("0.5x") { player?.rate = 0.5 }
                         Button("1.0x") { player?.rate = 1.0 }
                         Button("1.5x") { player?.rate = 1.5 }
                         Button("2.0x") { player?.rate = 2.0 }
                     } label: {
                         Label(String(format: "%.1fx", player?.rate ?? 1.0), systemImage: "speedometer")
                             .font(.subheadline)
                             .foregroundStyle(Theme.primaryLabel)
                             .padding(8)
                             .background(Theme.tertiaryBackground)
                             .cornerRadius(8)
                     }
                 }
                 .padding(.horizontal)
                 
                 if let analysis = recording.videoAnalysis {
                     // Detailed Metrics Grid
                     // Detailed Metrics Grid
                     LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)], spacing: 16) {
                         // 1. Gaze
                         MetricCard(
                             title: "Eye Contact",
                             value: String(format: "%.0f%%", (analysis.gaze?.engagementRatio ?? 0) * 100),
                             icon: "eye.fill",
                             color: .blue
                         )
                         
                         // 2. Movement
                         MetricCard(
                             title: "Stillness",
                             value: String(format: "%.0f%%", (analysis.movement?.stillnessScore ?? 0) * 100),
                             icon: "figure.stand",
                             color: (analysis.movement?.stillnessScore ?? 0) > 0.7 ? .green : .orange
                         )
                         
                         // 3. Expressions
                         MetricCard(
                             title: "Smiles",
                             value: "\(analysis.expression?.smileCount ?? 0)",
                             icon: "mouth",
                             color: .pink
                         )
                         
                         // 4. Framing
                         MetricCard(
                             title: "Framing",
                             value: (analysis.framing?.isCenteredScore ?? 0) > 0.8 ? "Good" : "Adjust",
                             icon: "viewfinder",
                             color: (analysis.framing?.isCenteredScore ?? 0) > 0.8 ? .green : .yellow
                         )
                     }
                     .padding()
                 }
            }
            .padding()
            
            Color.clear.frame(height: 20)
        }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)

        .background(Theme.background)
        .onAppear {
            setupPlayer()
        }
        .onDisappear {
            player?.pause()
        }
        .onReceive(timer) { _ in
            guard let player = player else { return }
            currentTime = player.currentTime().seconds
            updateActiveEvent()
        }
    }
    
    private func setupPlayer() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsPath.appendingPathComponent(recording.filename)
        player = AVPlayer(url: fileURL)
        player?.play()
        isPlaying = true
    }
    
    private func updateActiveEvent() {
        guard let analysis = recording.videoAnalysis else { return }
        // Simple Logic: Show event description if we are within 1.5 seconds of the event start
        if let event = analysis.events.first(where: { abs($0.timestamp - currentTime) < 1.5 }) {
            withAnimation {
                activeEvent = event
            }
        } else {
            withAnimation {
                activeEvent = nil
            }
        }
    }
    
    private func getPresenceColor(_ state: PresenceState) -> Color {
        switch state {
        case .present: return .green
        case .absent: return .red
        case .distracted: return .orange
        case .unsettled: return .yellow
        case .grounded: return .cyan
        case .smiling: return .pink
        case .fidgeting: return .yellow
        case .poorFraming: return .purple
        }
    }
}

struct StatusValue: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack {
            Text(label)
                .font(.caption)
                .foregroundStyle(Theme.secondaryLabel)
            Text(value)
                .font(.headline)
                .foregroundStyle(Theme.primaryLabel)
        }
    }
}

// MARK: - Audio Playback View (Original Logic)

struct AudioPlaybackView: View {
    @ObservedObject var voiceRecorder: VoiceRecorder
    @ObservedObject var storage: RecordingStorage
    let recording: Recording
    
    // ... Original Audio Logic State ...
    @State private var isDragging = false
    @State private var scrubbingTime: TimeInterval = 0
    @State private var initialScrubTime: TimeInterval = 0
    @State private var zoomScale: CGFloat = 1.0
    @State private var lastZoomScale: CGFloat = 1.0
    
    var body: some View {
        ScrollView {
            VStack {

                Color.clear.frame(height: 40)
            
            Text(formattedTime(isDragging ? scrubbingTime : voiceRecorder.currentTime))
                .font(.system(size: 40, weight: .light, design: .monospaced))
                .foregroundStyle(Theme.primaryLabel)
                .padding(.bottom, 20)
            
            // Audio Visualization Graph
            ZStack {
                GeometryReader { geometry in
                    let barWidth: CGFloat = 6 * zoomScale
                    let spacing: CGFloat = 4 * zoomScale
                    let totalBarWidth = barWidth + spacing
                    let totalWidth = CGFloat(voiceRecorder.audioSamples.count) * totalBarWidth
                    let duration = voiceRecorder.duration > 0 ? voiceRecorder.duration : 1
                    let pixelsPerSecond = totalWidth / duration
                    let timeToShow = isDragging ? scrubbingTime : voiceRecorder.currentTime
                    let percent = CGFloat(timeToShow / duration)
                    let currentX = percent * totalWidth
                    let centerOffset = geometry.size.width / 2
                    
                    VStack(alignment: .leading, spacing: 0) {
                        HStack(spacing: spacing) {
                            ForEach(voiceRecorder.audioSamples.indices, id: \.self) { index in
                                let sampleTime = Double(index) / Double(voiceRecorder.audioSamples.count) * duration
                                let color = getSegmentColor(at: sampleTime, segments: recording.analysis?.segments)
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(color)
                                    .frame(width: barWidth, height: min(250, max(4, CGFloat(voiceRecorder.audioSamples[index]) * 400)))
                            }
                        }
                        .frame(height: 250, alignment: .bottom)
                        
                        // Ruler
                        ZStack(alignment: .topLeading) {
                            Rectangle().fill(Color.gray).frame(height: 1).frame(width: totalWidth)
                            let secondsCount = Int(totalWidth / 200) + 1
                            ForEach(0..<secondsCount, id: \.self) { second in
                                let xPos = CGFloat(second) * 200.0
                                Rectangle().fill(Color.gray).frame(width: 2, height: 10).offset(x: xPos)
                                Text(String(format: "0:%02d", second)).font(.caption2).foregroundStyle(Theme.secondaryLabel).offset(x: xPos + 4, y: 12)
                                ForEach(1..<5) { tick in
                                    Rectangle().fill(Color.gray.opacity(0.5)).frame(width: 1, height: 5).offset(x: xPos + CGFloat(tick) * 40.0)
                                }
                            }
                        }
                        .frame(width: totalWidth, height: 30, alignment: .topLeading)
                    }
                    .frame(width: totalWidth, alignment: .leading)
                    .offset(x: centerOffset - currentX)
                    .contentShape(Rectangle())
                    .gesture(
                        SimultaneousGesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    if !isDragging {
                                        isDragging = true
                                        voiceRecorder.pausePlayback()
                                        let startCurrentX = (CGFloat(voiceRecorder.currentTime / duration) * totalWidth)
                                        let startOffset = centerOffset - startCurrentX
                                        let tapX = value.startLocation.x
                                        let waveformTapX = tapX - startOffset
                                        let tappedTime = Double(waveformTapX / totalWidth) * duration
                                        initialScrubTime = max(0, min(duration, tappedTime))
                                        scrubbingTime = initialScrubTime
                                    }
                                    let dragSeconds = Double(-value.translation.width / pixelsPerSecond)
                                    scrubbingTime = max(0, min(duration, initialScrubTime + dragSeconds))
                                }
                                .onEnded { value in
                                    voiceRecorder.seek(to: scrubbingTime)
                                    voiceRecorder.startPlayback()
                                    isDragging = false
                                },
                            MagnificationGesture()
                                .onChanged { scale in
                                    let delta = scale / lastZoomScale
                                    lastZoomScale = scale
                                    let newScale = zoomScale * delta
                                    zoomScale = min(max(newScale, 0.5), 5.0)
                                }
                                .onEnded { _ in lastZoomScale = 1.0 }
                        )
                    )
                }
                
                if let state = getSegmentState(at: isDragging ? scrubbingTime : voiceRecorder.currentTime, segments: recording.analysis?.segments) {
                    Text(state.rawValue)
                        .font(.caption2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(getColor(for: state))
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                        .offset(y: -130)
                }
                
                Rectangle().fill(Color.white).frame(width: 2, height: 280).offset(y: -15)
            }
            .frame(height: 280)
            .background(Theme.secondaryBackground)
            
            Color.clear.frame(height: 20)
            
            Button(action: {
                HapticManager.shared.light() // Light haptic for play/pause
                if voiceRecorder.isPlaying {
                    voiceRecorder.pausePlayback()
                } else {
                    voiceRecorder.startPlayback()
                }
            }) {
                Image(systemName: voiceRecorder.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 80)
                    .foregroundStyle(Theme.tint)
            }
            .padding()
            
            if let analysis = recording.analysis {
                VStack(spacing: 15) {
                    Text("Analysis Results").font(.headline).foregroundStyle(Theme.primaryLabel)
                    HStack(spacing: 20) {
                        VStack {
                            Text("Your State").font(.caption).foregroundStyle(Theme.secondaryLabel)
                            Text(analysis.communicationState.rawValue).font(.title3).fontWeight(.bold).foregroundStyle(getColor(for: analysis.communicationState))
                        }
                        VStack {
                            Text("Rate").font(.caption).foregroundStyle(Theme.secondaryLabel)
                            Text(String(format: "%.0f WPM", analysis.speechRate)).fontWeight(.medium).foregroundStyle(Theme.primaryLabel)
                        }
                        VStack {
                            Text("Pauses").font(.caption).foregroundStyle(Theme.secondaryLabel)
                            Text(String(format: "%.1f /min", analysis.pauseFrequency)).fontWeight(.medium).foregroundStyle(Theme.primaryLabel)
                        }
                    }
                    .padding().background(Theme.secondaryBackground).cornerRadius(10)
                    
                    if !analysis.transcription.isEmpty {
                        Text(analysis.transcription)
                            .font(.body)
                            .foregroundStyle(Theme.secondaryLabel)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Theme.tertiaryBackground)
                            .cornerRadius(10)
                    }
                }
                .padding(.horizontal)
            }
            }
            .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.background)
        .onAppear { voiceRecorder.startPlayback() }
        .onDisappear { voiceRecorder.stopPlayback() }
    }
    
    private func formattedTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        let milliseconds = Int((time * 100).truncatingRemainder(dividingBy: 100))
        return String(format: "%02d:%02d.%02d", minutes, seconds, milliseconds)
    }
    
    // Helpers
    private func getSegmentColor(at time: TimeInterval, segments: [AnalysisSegment]?) -> Color {
        guard let state = getSegmentState(at: time, segments: segments) else { return .gray }
        return getColor(for: state)
    }
    
    private func getSegmentState(at time: TimeInterval, segments: [AnalysisSegment]?) -> CommunicationState? {
        guard let segments = segments else { return nil }
        for segment in segments {
            if time >= segment.startTime && time <= segment.endTime { return segment.state }
        }
        return .neutral
    }
    
    private func getColor(for state: CommunicationState) -> Color {
        switch state {
        case .confident: return .green
        case .neutral: return .gray
        case .hesitant: return .orange
        case .unclear: return .red
        case .grounded: return .cyan
        }
    }
}

#Preview {
    let mockRecorder = VoiceRecorder()
    let mockStorage = RecordingStorage()
    let mockRecording = Recording(filename: "test.m4a", date: Date(), duration: 10.0, samples: [0.1, 0.3, 0.5, 0.8, 0.4, 0.2, 0.6, 0.9, 0.3])
    mockRecorder.audioSamples = [0.1, 0.3, 0.5, 0.8, 0.4, 0.2, 0.6, 0.9, 0.3]
    
    return PlaybackView(voiceRecorder: mockRecorder, storage: mockStorage, recording: mockRecording)
}

// MARK: - Smart Playback Helpers

struct TimelineLane: View {
    let duration: TimeInterval
    var segments: [AnalysisSegment]? = nil
    var events: [VisualEvent]? = nil
    var colorMap: ((CommunicationState) -> Color)? = nil
    var baseColor: Color = .blue
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Audio Segments
                if let segments = segments, let colorMap = colorMap {
                    ForEach(segments, id: \.startTime) { segment in
                        let startX = CGFloat(segment.startTime / duration) * geometry.size.width
                        let width = CGFloat((segment.endTime - segment.startTime) / duration) * geometry.size.width
                        
                        Rectangle()
                            .fill(colorMap(segment.state))
                            .frame(width: max(2, width), height: 8)
                            .cornerRadius(4)
                            .position(x: startX + width/2, y: 4)
                    }
                }
                
                // Visual Events
                if let events = events {
                    ForEach(events) { event in
                        let startX = CGFloat(event.timestamp / duration) * geometry.size.width
                        Rectangle()
                            .fill(baseColor)
                            .frame(width: 4, height: 8)
                            .cornerRadius(2)
                            .position(x: startX, y: 4)
                    }
                }
            }
        }
        .frame(height: 8)
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(color)
                .frame(width: 44, height: 44)
                .background(color.opacity(0.1))
                .clipShape(Circle())
            
            Spacer()
            
            Text(value)
                .font(.system(.title2, design: .rounded))
                .fontWeight(.bold)
                .foregroundStyle(Theme.primaryLabel)
                .minimumScaleFactor(0.8)
                
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(Theme.secondaryLabel)
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 150, alignment: .topLeading)
        .background(Theme.secondaryBackground) // Using secondary for card look
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

extension VideoPlaybackView {
    func generateCrossModalInsights(video: VideoAnalysisResult, audio: AudioAnalysisResult) -> [String] {
        var insights: [String] = []
        
        // 1. Hesitation + Distraction
        // Check if Hesitant segments overlap with Distracted events
        let hesitantSegments = audio.segments.filter { $0.state == .hesitant }
        var overlapCount = 0
        
        for segment in hesitantSegments {
            let overlaps = video.events.contains { event in
                event.type == .distracted && event.timestamp >= segment.startTime && event.timestamp <= segment.endTime
            }
            if overlaps { overlapCount += 1 }
        }
        
        if overlapCount > 0 {
            insights.append("You look away when hesitating.")
        }
        
        // 2. High Fidgeting
        if (video.movement?.stillnessScore ?? 1.0) < 0.4 {
            insights.append("High movement detected while speaking.")
        }
        
        // 3. Eye Contact Streak
        if (video.gaze?.longestStreak ?? 0) > 5.0 {
            insights.append("Great eye contact streaks!")
        }
        
        // 4. Smile Timing
        // Check if smile is near start
        if let firstSmile = video.expression?.smileTimestamps.first, firstSmile < 3.0 {
            insights.append("Great warm start with a smile.")
        } else if (video.expression?.smileCount ?? 0) == 0 {
             insights.append("Try adding a smile for warmth.")
        }
        
        return insights
    }
}
