import SwiftUI
import AVFoundation

struct PlaybackView: View {
    @ObservedObject var voiceRecorder: VoiceRecorder
    @ObservedObject var storage: RecordingStorage
    let recording: Recording
    
    @Environment(\.dismiss) var dismiss
    @State private var showDeleteAlert = false
    @State private var isDragging = false
    @State private var scrubbingTime: TimeInterval = 0
    @State private var initialScrubTime: TimeInterval = 0
    
    private func formattedTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        let milliseconds = Int((time * 100).truncatingRemainder(dividingBy: 100))
        return String(format: "%02d:%02d.%02d", minutes, seconds, milliseconds)
    }
    
    var body: some View {
        VStack {
            Text("Recording Playback")
                .font(.title)
                .padding()
                .foregroundStyle(.white)
            
            Spacer()
            
            // Time Display
            Text(formattedTime(isDragging ? scrubbingTime : voiceRecorder.currentTime))
                .font(.system(size: 40, weight: .light, design: .monospaced))
                .foregroundStyle(.white)
                .padding(.bottom, 20)
            
            // Audio Visualization Graph
            ZStack {
                GeometryReader { geometry in
                    let barWidth: CGFloat = 6
                    let spacing: CGFloat = 4
                    let totalBarWidth = barWidth + spacing
                    let totalWidth = CGFloat(voiceRecorder.audioSamples.count) * totalBarWidth
                    
                    // Center the current time
                    let duration = voiceRecorder.duration > 0 ? voiceRecorder.duration : 1
                    
                    // Pixels per second calculation
                    // totalWidth corresponds to `duration`
                    let pixelsPerSecond = totalWidth / duration
                    
                    // Use scrubbing time if dragging, else current playback time
                    let timeToShow = isDragging ? scrubbingTime : voiceRecorder.currentTime
                    
                    let percent = CGFloat(timeToShow / duration)
                    let currentX = percent * totalWidth
                    let centerOffset = geometry.size.width / 2
                    
                    // Waveform View
                    VStack(alignment: .leading, spacing: 0) {
                        // Waveform
                        HStack(spacing: spacing) {
                            ForEach(voiceRecorder.audioSamples.indices, id: \.self) { index in
                                let sampleTime = Double(index) / Double(voiceRecorder.audioSamples.count) * duration
                                let color = getSegmentColor(at: sampleTime, segments: recording.analysis?.segments)
                                
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(color)
                                    // Boost amplitude to fill height: * 400. Clamp to max 250.
                                    .frame(width: barWidth, height: min(250, max(4, CGFloat(voiceRecorder.audioSamples[index]) * 400)))
                            }
                        }
                        .frame(height: 250, alignment: .bottom) // Align bottom to sit on ruler
                        
                        // Ruler
                        ZStack(alignment: .topLeading) {
                            // Ruler Line
                            Rectangle()
                                .fill(Color.gray)
                                .frame(height: 1)
                                .frame(width: totalWidth)
                            
                            // Ticks and Labels
                            let secondsCount = Int(totalWidth / 200) + 1
                            
                            ForEach(0..<secondsCount, id: \.self) { second in
                                let xPos = CGFloat(second) * 200.0
                                
                                // Major Tick
                                Rectangle()
                                    .fill(Color.gray)
                                    .frame(width: 2, height: 10)
                                    .offset(x: xPos)
                                
                                // Label
                                Text(String(format: "0:%02d", second))
                                    .font(.caption2)
                                    .foregroundStyle(.gray)
                                    .offset(x: xPos + 4, y: 12)
                                
                                // Minor Ticks
                                ForEach(1..<5) { tick in
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.5))
                                        .frame(width: 1, height: 5)
                                        .offset(x: xPos + CGFloat(tick) * 40.0)
                                }
                            }
                        }
                        .frame(width: totalWidth, height: 30, alignment: .topLeading)
                    }
                    .frame(width: totalWidth, alignment: .leading)
                    .offset(x: centerOffset - currentX)
                    // Gesture is attached to the CONTAINER (GeometryReader), not the moving waveform
                    .contentShape(Rectangle()) // Ensure hit testing works on empty space
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                if !isDragging {
                                    isDragging = true
                                    voiceRecorder.pausePlayback()
                                    
                                    // Calculate Seek Time from Tap Location (Start)
                                    // 1. Calculate the 'offset' of the waveform at the MOMENT dragging started
                                    //    Equation: ViewX = WaveformX + Offset
                                    //    Offset = Center - CurrentX (at start)
                                    let startCurrentX = (CGFloat(voiceRecorder.currentTime / duration) * totalWidth)
                                    let startOffset = centerOffset - startCurrentX
                                    
                                    // 2. Find where the tap occurred in Waveform Coordinates
                                    //    TapX = StartLocationX
                                    //    WaveformTapX = TapX - StartOffset
                                    let tapX = value.startLocation.x
                                    let waveformTapX = tapX - startOffset
                                    
                                    // 3. Convert WaveformTapX to Time
                                    let tappedTime = Double(waveformTapX / totalWidth) * duration
                                    
                                    initialScrubTime = max(0, min(duration, tappedTime))
                                    scrubbingTime = initialScrubTime
                                }
                                
                                // Handle Dragging relatively from the Initial Tap
                                // DragDelta is translation. width
                                // Moving finger LEFT (negative translation) should move Time FORWARD?
                                // Standard scrolling: Drag Left -> View moves Left -> Show content to the Right (Later time).
                                // So Time increases.
                                // Drag Delta Pixels -> Time Delta
                                let dragSeconds = Double(-value.translation.width / pixelsPerSecond)
                                
                                
                                let newTime = max(0, min(duration, initialScrubTime + dragSeconds))
                                scrubbingTime = newTime
                            }
                            .onEnded { value in
                                // Finalize Seek
                                voiceRecorder.seek(to: scrubbingTime)
                                voiceRecorder.startPlayback()
                                isDragging = false
                            }
                    )
                }
                
                // Tooltip (Floating Pill) - Always Visible
                if let state = getSegmentState(at: isDragging ? scrubbingTime : voiceRecorder.currentTime, segments: recording.analysis?.segments) {
                    Text(state.rawValue)
                        .font(.caption2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(getColor(for: state))
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                        .offset(y: -130) // Positioned just below the top edge
                }
                
                // Static Playhead
                Rectangle()
                    .fill(Color.white)
                    .frame(width: 2, height: 280) // Taller to cover ruler too
                    .offset(y: -15) // Adjust alignment
            }
            .frame(height: 280) // Adjusted total height
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
            
            // Audio Analysis Results
            if let analysis = recording.analysis {
                VStack(spacing: 15) {
                    Text("Analysis Results")
                        .font(.headline)
                        .foregroundStyle(.white)
                    
                    HStack(spacing: 20) {
                        VStack {
                            Text("Your State")
                                .font(.caption)
                                .foregroundStyle(.gray)
                            Text(analysis.communicationState.rawValue)
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundStyle(getColor(for: analysis.communicationState))
                        }
                        
                        VStack {
                            Text("Rate")
                                .font(.caption)
                                .foregroundStyle(.gray)
                            Text(String(format: "%.0f WPM", analysis.speechRate))
                                .fontWeight(.medium)
                                .foregroundStyle(.white)
                        }
                        
                        VStack {
                            Text("Pauses")
                                .font(.caption)
                                .foregroundStyle(.gray)
                            Text(String(format: "%.1f /min", analysis.pauseFrequency))
                                .fontWeight(.medium)
                                .foregroundStyle(.white)
                        }
                    }
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(10)
                    
                    if !analysis.transcription.isEmpty {
                        ScrollView {
                            Text(analysis.transcription)
                                .font(.body)
                                .foregroundStyle(.white.opacity(0.8))
                                .padding()
                        }
                        .frame(maxHeight: 150)
                        .background(Color.black.opacity(0.2))
                        .cornerRadius(10)
                    }
                }
                .padding(.horizontal)
            } else if let error = recording.analysisError {
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.title)
                        .foregroundStyle(.yellow)
                    
                    Text("Analysis Unavailable")
                        .font(.headline)
                        .foregroundStyle(.white)
                    
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.white.opacity(0.1))
                .cornerRadius(10)
                .padding(.horizontal)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
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
        .onAppear {
            voiceRecorder.startPlayback()
        }
        .onDisappear {
            voiceRecorder.stopPlayback()
        }
    }
    
    private func getSegmentColor(at time: TimeInterval, segments: [AnalysisSegment]?) -> Color {
        guard let state = getSegmentState(at: time, segments: segments) else { return .gray }
        return getColor(for: state)
    }
    
    private func getSegmentState(at time: TimeInterval, segments: [AnalysisSegment]?) -> CommunicationState? {
        guard let segments = segments else { return nil }
        
        for segment in segments {
            if time >= segment.startTime && time <= segment.endTime {
                return segment.state
            }
        }
        return .neutral // Default if no segment found but analyzing? Or nil? Let's say .neutral (Gray)
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
    
    private func getRecordingName() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        let fullName = formatter.string(from: recording.date)
        return fullName.count > 20 ? String(fullName.prefix(20)) + "..." : fullName
    }
}

#Preview {
    let mockRecorder = VoiceRecorder()
    let mockStorage = RecordingStorage()
    let mockRecording = Recording(filename: "test.m4a", date: Date(), duration: 10.0, samples: [0.1, 0.3, 0.5, 0.8, 0.4, 0.2, 0.6, 0.9, 0.3])
    mockRecorder.audioSamples = [0.1, 0.3, 0.5, 0.8, 0.4, 0.2, 0.6, 0.9, 0.3]
    
    return PlaybackView(voiceRecorder: mockRecorder, storage: mockStorage, recording: mockRecording)
}
