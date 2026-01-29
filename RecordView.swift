import SwiftUI

struct RecordView: View {
    @StateObject var voiceRecorder = VoiceRecorder()
    @StateObject var cameraManager = CameraManager()
    @StateObject var videoAnalyzer = VideoAnalyzer()
    @ObservedObject var storage: RecordingStorage
    
    @State private var showPlayback = false
    @State private var isAnalyzing = false
    @State private var selectedRecording: Recording?
    @State private var recordingToDelete: Recording?
    @State private var showDeleteAlert = false
    @State private var touchLocation: CGPoint = .zero
    
    // New State for Camera Mode
    @State private var isCameraMode = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background & Glow
                Color.black.ignoresSafeArea()
                
                if isCameraMode {
                    if cameraManager.permissionGranted {
                        CameraPreview(session: cameraManager.session)
                            .ignoresSafeArea()
                            .overlay(
                                Color.black.opacity(cameraManager.isRecording ? 0.0 : 0.2)
                            )
                    } else {
                        Text("Camera access required")
                            .foregroundStyle(.gray)
                    }
                } else {
                    // Audio Mode Visualization
                    ParticleView(amplitude: voiceRecorder.currentAmplitude, touchLocation: touchLocation)
                        .ignoresSafeArea()
                    
                    if voiceRecorder.isRecording {
                        Circle()
                            .fill(
                                RadialGradient(gradient: Gradient(colors: [.red.opacity(0.6), .red.opacity(0.0)]), center: .center, startRadius: 0, endRadius: 400)
                            )
                            .blur(radius: 50)
                            .scaleEffect(1.0 + CGFloat(voiceRecorder.currentAmplitude) * 2.0)
                            .position(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height + 20)
                            .animation(.easeOut(duration: 0.1), value: voiceRecorder.currentAmplitude)
                    }
                }
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Main Recording Section
                        VStack(spacing: 20) {
                            Spacer() // Push content down
                            
                            // Custom Mode Toggle
                            if !voiceRecorder.isRecording && !cameraManager.isRecording {
                                HStack(spacing: 0) {
                                    Button(action: { isCameraMode = false }) {
                                        Text("Audio")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 8)
                                            .background(isCameraMode ? Color.clear : Color.white.opacity(0.2))
                                            .foregroundStyle(.white)
                                            .cornerRadius(8)
                                    }
                                    .highPriorityGesture(TapGesture().onEnded { isCameraMode = false })
                                    
                                    Button(action: { isCameraMode = true }) {
                                        Text("Camera")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 8)
                                            .background(isCameraMode ? Color.white.opacity(0.2) : Color.clear)
                                            .foregroundStyle(.white)
                                            .cornerRadius(8)
                                    }
                                    .highPriorityGesture(TapGesture().onEnded { isCameraMode = true })
                                }
                                .padding(4)
                                .background(Color.black.opacity(0.3)) // Background for the pill
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                )
                                .frame(width: 200)
                                .padding(.bottom, 10)
                            }
                            
                            if !isCameraMode {
                                MotivationalMessageView()
                                    .padding(.bottom, 20)
                            } else if cameraManager.isRecording {
                                // Camera Feedback
                                Text(videoAnalyzer.currentPresence.rawValue)
                                    .font(.headline)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 16)
                                    .background(.ultraThinMaterial)
                                    .cornerRadius(20)
                                    .foregroundStyle(.white)
                            }
                            
                            Button(action: {
                                if isCameraMode {
                                    handleCameraRecording()
                                } else {
                                    handleAudioRecording()
                                }
                            }) {
                                ZStack {
                                    if (isCameraMode && cameraManager.isRecording) || (!isCameraMode && voiceRecorder.isRecording) {
                                        Image(systemName: "stop.circle.fill")
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 100, height: 100)
                                            .foregroundColor(.red)
                                    } else {
                                        Image(systemName: "circle.fill") // Outer ring
                                            .resizable()
                                            .frame(width: 100, height: 100)
                                            .foregroundColor(.white)
                                        
                                        Image(systemName: "circle.fill") // Inner red button
                                            .resizable()
                                            .frame(width: 80, height: 80)
                                            .foregroundColor(.red)
                                    }
                                }
                            }
                            
                            Text(recordingStatusText)
                                .font(.headline)
                                .padding()
                                .foregroundStyle(isCameraMode ? .white : .gray)
                                .shadow(radius: isCameraMode ? 2 : 0)
                            
                            Spacer()
                        }
                        .frame(height: UIScreen.main.bounds.height - 200)
                        
                        // Past Recordings Section
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Past Recordings")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                                .padding(.horizontal)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            if storage.recordings.isEmpty {
                                Text("No recordings yet")
                                    .font(.subheadline)
                                    .foregroundStyle(.gray)
                                    .padding(.horizontal)
                                    .padding(.bottom, 40)
                            } else {
                                LazyVGrid(columns: [
                                    GridItem(.flexible(), spacing: 15),
                                    GridItem(.flexible(), spacing: 15),
                                    GridItem(.flexible(), spacing: 15)
                                ], spacing: 15) {
                                    ForEach(Array(storage.recordings.enumerated()), id: \.element.id) { index, recording in
                                        Button(action: {
                                            selectedRecording = recording
                                            // Handle loading based on type
                                            if !recording.isVideo {
                                                voiceRecorder.loadRecording(recording)
                                            }
                                            showPlayback = true
                                        }) {
                                            RecordingCard(recording: recording, index: index)
                                        }
                                        .onLongPressGesture {
                                            recordingToDelete = recording
                                            showDeleteAlert = true
                                        }
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.bottom, 100)
                            }
                        }
                        .background(isCameraMode ? Color.black.opacity(0.8) : Color.clear) // Darken bg in camera mode
                        .opacity((voiceRecorder.isRecording || cameraManager.isRecording) ? 0 : 1)
                        .animation(.easeInOut(duration: 0.3), value: (voiceRecorder.isRecording || cameraManager.isRecording))
                    }
                }
                .scrollDisabled(cameraManager.isRecording) // Disable scroll while recording video to keep UI stable
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .safeAreaInset(edge: .top) {
                    Text("Echo 🎤")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .shadow(radius: isCameraMode ? 4 : 0)
                }
                
                // Live Audio Visualizer (Audio Mode Only)
                if voiceRecorder.isRecording && !isCameraMode {
                    AudioVisualizer(amplitude: voiceRecorder.currentAmplitude)
                }
                
                // Analysis Loading Screen
                if isAnalyzing {
                    ZStack {
                        Color.black.ignoresSafeArea()
                        if !isCameraMode {
                             ParticleView().ignoresSafeArea().opacity(0.5)
                        }
                        
                        VStack(spacing: 30) {
                            AnalysisLoadingView()
                                .frame(width: 200, height: 200)
                            
                            Text("Analyzing Presence...")
                                .font(.title3)
                                .fontWeight(.medium)
                                .foregroundStyle(.white)
                                .opacity(0.8)
                        }
                    }
                    .transition(.opacity)
                    .zIndex(2)
                }
            }
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        touchLocation = value.location
                    }
                    .onEnded { _ in
                        touchLocation = .zero
                    }
            )
            .navigationDestination(isPresented: $showPlayback) {
                if let recording = selectedRecording {
                    PlaybackView(voiceRecorder: voiceRecorder, storage: storage, recording: recording)
                }
            }
            .onAppear {
                voiceRecorder.requestPermission()
                cameraManager.setFrameDelegate(videoAnalyzer) // Connect analyzer
            }
        }
        .alert("Delete Recording", isPresented: $showDeleteAlert, presenting: recordingToDelete) { recording in
            Button("Cancel", role: .cancel) { }
                .tint(.white)
            Button("Delete", role: .destructive) {
                storage.deleteRecording(recording)
            }
            .tint(.red)
        } message: { recording in
            Text("Are you sure you want to delete \"\(getRecordingName(recording))\"?")
        }
    }
    
    var recordingStatusText: String {
        if isCameraMode {
            return cameraManager.isRecording ? "Recording Presence..." : "Tap to record"
        } else {
            return voiceRecorder.isRecording ? "Recording Audio..." : "Tap to record"
        }
    }
    
    // MARK: - Handlers
    
    func handleAudioRecording() {
        if voiceRecorder.isRecording {
            voiceRecorder.stopRecording()
            withAnimation { isAnalyzing = true }
            
            Task { @MainActor in
                if let recording = await voiceRecorder.getCurrentRecording() {
                    storage.saveRecording(recording)
                    selectedRecording = recording
                    
                    try? await Task.sleep(nanoseconds: 2 * 1_000_000_000)
                    
                    withAnimation {
                        isAnalyzing = false
                        showPlayback = true
                    }
                } else {
                    withAnimation { isAnalyzing = false }
                }
            }
        } else {
            voiceRecorder.startRecording()
        }
    }
    
    func handleCameraRecording() {
        if cameraManager.isRecording {
            Task {
                cameraManager.stopRecording()
                let videoAnalysis = videoAnalyzer.stopAnalysis()
                
                withAnimation { isAnalyzing = true }
                
                // Small delay to ensure file is written
                try? await Task.sleep(nanoseconds: 1 * 1_000_000_000)
                
                if let url = cameraManager.outputFileURL {
                    // Create Video Recording Object
                    let recording = Recording(
                        filename: url.lastPathComponent,
                        date: Date(),
                        duration: cameraManager.recordedDuration,
                        samples: [], // No audio waveform for now
                        isVideo: true,
                        videoAnalysis: videoAnalysis
                    )
                    
                    storage.saveRecording(recording)
                    selectedRecording = recording
                    
                    try? await Task.sleep(nanoseconds: 2 * 1_000_000_000) // Analysis delay for effect
                    
                    withAnimation {
                        isAnalyzing = false
                        showPlayback = true
                    }
                } else {
                    print("Error: No file URL found")
                    withAnimation { isAnalyzing = false }
                }
            }
        } else {
            videoAnalyzer.startAnalysis()
            cameraManager.startRecording()
        }
    }
    
    private func getRecordingName(_ recording: Recording) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        let fullName = formatter.string(from: recording.date)
        return fullName.count > 20 ? String(fullName.prefix(20)) + "..." : fullName
    }
}


// Extracted Subviews for cleaner code

struct RecordingCard: View {
    let recording: Recording
    let index: Int
    
    var body: some View {
        VStack(spacing: 8) {
            Group {
                if recording.isVideo {
                    Image(systemName: "video.fill")
                        .font(.system(size: 30))
                } else {
                    Image(systemName: "waveform")
                        .font(.system(size: 30))
                }
            }
            .foregroundStyle(
                Color(hue: (Double(index) * 0.1).truncatingRemainder(dividingBy: 1.0), saturation: 1.0, brightness: 1.0)
            )
            
            Text(recording.date, style: .date)
                .font(.caption2)
                .foregroundStyle(.white)
                .lineLimit(1)
            
            Text(formatDuration(recording.duration))
                .font(.caption2)
                .foregroundStyle(.gray)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .aspectRatio(1, contentMode: .fit)
        .background {
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.ultraThinMaterial)
                
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [.white.opacity(0.25), .white.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.5), .white.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct AudioVisualizer: View {
    let amplitude: Float
    
    var body: some View {
        VStack {
            Spacer()
            HStack(spacing: 3) {
                ForEach(0..<60) { i in
                    let x = CGFloat(i - 30)
                    let radius: CGFloat = 38
                    let shapeFactor = max(0, sqrt(pow(radius, 2) - pow(x, 2))) / radius
                    
                    let noise = CGFloat.random(in: 0.5...1.5)
                    let height = CGFloat(amplitude) * 200.0 * shapeFactor * noise
                    
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color.red)
                        .frame(width: 4, height: max(0, height))
                }
            }
            .frame(maxWidth: .infinity, alignment: .bottom)
            .padding(.bottom, 0)
            .offset(y: 20)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .ignoresSafeArea(edges: .bottom)
    }
}
