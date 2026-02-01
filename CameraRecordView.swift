import SwiftUI

struct CameraRecordView: View {
    @StateObject var cameraManager = CameraManager()
    @StateObject var videoAnalyzer = VideoAnalyzer()
    @ObservedObject var storage: RecordingStorage
    @EnvironmentObject var languageManager: LanguageManager
    
    @State private var showPlayback = false
    @State private var isAnalyzing = false
    @State private var selectedRecording: Recording?
    @State private var showCountdown = false
    @State private var countdownNumber = 3
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                
                if cameraManager.permissionGranted {
                    CameraPreview(session: cameraManager.session)
                        .ignoresSafeArea()
                        .overlay(
                            Color.black.opacity(cameraManager.isRecording ? 0.0 : 0.2)
                        )
                } else {
                    VStack {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(.gray)
                            .padding()
                        Text(languageManager.t("Camera access required"))
                            .font(.headline)
                            .foregroundStyle(.gray)
                        Button(languageManager.t("Open Settings")) {
                            // Link to settings would go here
                        }
                        .padding()
                    }
                }
                
                if !cameraManager.isRecording {
                    VStack {
                        Spacer()
                        MotivationalMessageView(type: .camera)
                            .transition(.opacity)
                        Spacer()
                    }
                    .ignoresSafeArea()
                }

                VStack(spacing: 0) {
                    if cameraManager.isRecording {
                        // Camera Feedback Overlay
                        Text(videoAnalyzer.currentPresence.rawValue)
                            .font(.headline)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(.ultraThinMaterial)
                            .background(.ultraThinMaterial)
                            .cornerRadius(20)
                            .foregroundStyle(.white)
                            .padding(.top, 20)
                            .accessibilityLabel(languageManager.t("Presence Status"))
                            .accessibilityValue(videoAnalyzer.currentPresence.rawValue)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        handleCameraRecording()
                    }) {
                        ZStack {
                            if cameraManager.isRecording {
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
                                    .frame(width: 75, height: 75)
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    .accessibilityLabel(cameraManager.isRecording ? languageManager.t("Stop Recording") : languageManager.t("Start Recording"))
                    .accessibilityAddTraits(.isButton)
                    
                    Text(cameraManager.isRecording ? languageManager.t("Recording Presence...") : languageManager.t("Tap to record"))
                        .font(.headline)
                        .padding()
                        .foregroundStyle(.white)
                        .shadow(radius: 2)
                    
                    Spacer().frame(height: 50)
                }
                
                // Analysis Loading Screen
                if isAnalyzing {
                    ZStack {
                        Color.black.ignoresSafeArea()
                        VStack(spacing: 30) {
                            AnalysisLoadingView()
                                .frame(width: 200, height: 200)
                            
                            Text(languageManager.t("Analyzing Presence..."))
                                .font(.title3)
                                .fontWeight(.medium)
                                .foregroundStyle(.white)
                                .opacity(0.8)
                        }
                    }
                    .transition(.opacity)
                    .zIndex(2)
                    .onAppear {
                        UIAccessibility.post(notification: .announcement, argument: languageManager.t("Analyzing Presence..."))
                    }
                }
                
                // Countdown Overlay
                if showCountdown {
                    ZStack {
                        Color.black.opacity(0.7).ignoresSafeArea()
                        Text("\(countdownNumber)")
                            .font(.system(size: 120, weight: .bold))
                            .foregroundStyle(.white)
                            .shadow(color: .red, radius: 20)
                            .scaleEffect(countdownNumber > 0 ? 1.0 : 0.5)
                            .opacity(countdownNumber > 0 ? 1.0 : 0.0)
                    }
                    .transition(.opacity)
                    .zIndex(3)
                }
            }
            .navigationTitle(languageManager.t("Camera"))
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Theme.background.opacity(0.4), for: .navigationBar)
            .navigationDestination(isPresented: $showPlayback) {
                if let recording = selectedRecording {
                    // For playback we need a dummy voiceRecorder as PlaybackView requires it
                    // The video view inside ignores it anyway
                    PlaybackView(voiceRecorder: VoiceRecorder(), storage: storage, recording: recording)
                }
            }
            .onAppear {
                cameraManager.setFrameDelegate(videoAnalyzer)
            }
        }
    }
    
    func handleCameraRecording() {
        if cameraManager.isRecording {
            HapticManager.shared.heavy() // Heavy haptic when stopping
            Task {
                cameraManager.stopRecording()
                let videoAnalysis = videoAnalyzer.stopAnalysis()
                
                withAnimation { isAnalyzing = true }
                
                // Small delay to ensure file is written
                try? await Task.sleep(nanoseconds: 1 * 1_000_000_000)
                
                if let url = cameraManager.outputFileURL {
                    // 1. Run Audio Analysis on the video file (extracts audio track)
                    var audioAnalysis: AudioAnalysisResult?
                    do {
                       let analyzer = AudioAnalyzer()
                       audioAnalysis = try await analyzer.analyze(url: url)
                    } catch {
                        print("Audio analysis for video failed: \(error)")
                    }

                    // 2. Create Video Recording Object with BOTH analyses
                    let recording = Recording(
                        filename: url.lastPathComponent,
                        date: Date(),
                        duration: cameraManager.recordedDuration,
                        samples: [], // No audio waveform visualization for video preview in list yet
                        analysis: audioAnalysis, // <--- Store Audio Intelligence
                        isVideo: true,
                        videoAnalysis: videoAnalysis
                    )
                    
                    storage.saveRecording(recording)
                    selectedRecording = recording
                    
                    try? await Task.sleep(nanoseconds: 2 * 1_000_000_000) // Analysis delay for effect
                    
                    HapticManager.shared.success() // Success haptic after analysis
                    withAnimation {
                        isAnalyzing = false
                        showPlayback = true
                    }
                } else {
                    HapticManager.shared.error() // Error haptic if recording failed
                    withAnimation { isAnalyzing = false }
                }
            }
        } else {
            // Start countdown before recording
            Task {
                withAnimation { showCountdown = true }
                
                // Countdown from 3 to 1
                for i in (1...3).reversed() {
                    countdownNumber = i
                    UIAccessibility.post(notification: .announcement, argument: "\(i)")
                    HapticManager.shared.medium() // Haptic for each countdown number
                    try? await Task.sleep(nanoseconds: 1 * 1_000_000_000)
                }
                
                // Hide countdown and start recording
                withAnimation { showCountdown = false }
                HapticManager.shared.heavy() // Heavy haptic when recording actually starts
                videoAnalyzer.startAnalysis()
                cameraManager.startRecording()
            }
        }
    }
}
