import SwiftUI
import AVFoundation
import AVKit

struct PlaybackView: View {
    @ObservedObject var voiceRecorder: VoiceRecorder
    @ObservedObject var storage: RecordingStorage
    let recording: Recording
    
    @Environment(\.dismiss) var dismiss
    @State private var showDeleteAlert = false
    
    var body: some View {
        Group {
            if recording.isVideo {
                VideoPlaybackView(recording: recording, storage: storage)
            } else {
                AudioPlaybackView(voiceRecorder: voiceRecorder, storage: storage, recording: recording)
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showDeleteAlert = true
                }) {
                    Image(systemName: "trash")
                    .foregroundColor(.red)
                }
            }
        }
        .alert("Delete Recording", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
                .tint(.white)
            Button("Delete", role: .destructive) {
                storage.deleteRecording(recording)
                dismiss()
            }
            .tint(.red)
        } message: {
            Text("Are you sure you want to delete \"\(getRecordingName())\"?")
        }
    }
    
    func getRecordingName() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        let fullName = formatter.string(from: recording.date)
        return fullName.count > 20 ? String(fullName.prefix(20)) + "..." : fullName
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
        VStack {
            // Video Player
            ZStack(alignment: .bottom) {
                if let player = player {
                    VideoPlayer(player: player)
                        .aspectRatio(16/9, contentMode: .fit) // Standard video aspect
                        .cornerRadius(12)
                        .padding()
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .aspectRatio(16/9, contentMode: .fit)
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
            
            // Timeline
            VStack(alignment: .leading, spacing: 5) {
                Text("Presence Timeline")
                    .font(.caption)
                    .foregroundStyle(.gray)
                    .padding(.horizontal)
                
                GeometryReader { geometry in
                     ZStack(alignment: .leading) {
                         // Background Track
                         RoundedRectangle(cornerRadius: 4)
                             .fill(Color.gray.opacity(0.2))
                             .frame(height: 20)
                         
                         // Events
                         if let analysis = recording.videoAnalysis {
                             ForEach(analysis.events) { event in
                                 let startX = CGFloat(event.timestamp / recording.duration) * geometry.size.width
                                 // Heuristic width: assume event lasts 2 seconds for visual clarity or until next event?
                                 // Let's just make them markers
                                 let markerWidth: CGFloat = 4
                                 
                                 Rectangle()
                                     .fill(getPresenceColor(event.type))
                                     .frame(width: markerWidth, height: 20)
                                     .position(x: startX, y: 10)
                             }
                         }
                         
                         // Playhead
                         Rectangle()
                             .fill(Color.white)
                             .frame(width: 2, height: 20)
                             .position(x: CGFloat(currentTime / recording.duration) * geometry.size.width, y: 10)
                     }
                }
                .frame(height: 20)
                .padding(.horizontal)
            }
            .padding(.top, 10)
            
            // Analysis Summary
            if let analysis = recording.videoAnalysis {
                 HStack(spacing: 20) {
                     StatusValue(label: "Presence Score", value: String(format: "%.0f%%", analysis.presenceScore * 100))
                     StatusValue(label: "Gaze Stability", value: String(format: "%.0f%%", analysis.gazeStabilityScore * 100))
                 }
                 .padding()
                 .frame(maxWidth: .infinity)
                 .background(Color.white.opacity(0.1))
                 .cornerRadius(12)
                 .padding()
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
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
                .foregroundStyle(.gray)
            Text(value)
                .font(.headline)
                .foregroundStyle(.white)
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
        VStack {
            Text("Recording Playback")
                .font(.title)
                .padding()
                .foregroundStyle(.white)
            
            Spacer()
            
            Text(formattedTime(isDragging ? scrubbingTime : voiceRecorder.currentTime))
                .font(.system(size: 40, weight: .light, design: .monospaced))
                .foregroundStyle(.white)
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
                                Text(String(format: "0:%02d", second)).font(.caption2).foregroundStyle(.gray).offset(x: xPos + 4, y: 12)
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
            .background(Color.black.opacity(0.3))
            
            Spacer()
            
            Button(action: {
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
                    .foregroundStyle(.red)
            }
            .padding()
            
            if let analysis = recording.analysis {
                VStack(spacing: 15) {
                    Text("Analysis Results").font(.headline).foregroundStyle(.white)
                    HStack(spacing: 20) {
                        VStack {
                            Text("Your State").font(.caption).foregroundStyle(.gray)
                            Text(analysis.communicationState.rawValue).font(.title3).fontWeight(.bold).foregroundStyle(getColor(for: analysis.communicationState))
                        }
                        VStack {
                            Text("Rate").font(.caption).foregroundStyle(.gray)
                            Text(String(format: "%.0f WPM", analysis.speechRate)).fontWeight(.medium).foregroundStyle(.white)
                        }
                        VStack {
                            Text("Pauses").font(.caption).foregroundStyle(.gray)
                            Text(String(format: "%.1f /min", analysis.pauseFrequency)).fontWeight(.medium).foregroundStyle(.white)
                        }
                    }
                    .padding().background(Color.white.opacity(0.1)).cornerRadius(10)
                    
                    if !analysis.transcription.isEmpty {
                        ScrollView {
                            Text(analysis.transcription).font(.body).foregroundStyle(.white.opacity(0.8)).padding()
                        }
                        .frame(maxHeight: 150)
                        .background(Color.black.opacity(0.2))
                        .cornerRadius(10)
                    }
                }
                .padding(.horizontal)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
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
