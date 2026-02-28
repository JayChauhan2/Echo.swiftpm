import SwiftUI

struct RecordView: View {
    @StateObject var voiceRecorder = VoiceRecorder()
    @ObservedObject var storage: RecordingStorage
    @EnvironmentObject var effectsState: GlobalEffectsState
    @EnvironmentObject var languageManager: LanguageManager
    
    @State private var showPlayback = false
    @State private var isAnalyzing = false
    @State private var selectedRecording: Recording?
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background - Remove solid color to show Global Particles
                // Theme background is handled on the NavigationStack container
                
                ParticleView(amplitude: effectsState.amplitude, touchLocation: effectsState.touchLocation, gravity: effectsState.gravity)
                    .ignoresSafeArea()
                
                // Audio Amplitude Sync
                Color.clear
                    .onChange(of: voiceRecorder.currentAmplitude) { newValue in
                        effectsState.amplitude = newValue
                    }
                    .onAppear {
                        effectsState.amplitude = 0.0
                    }
                
                // Recording Ripple Effect
                if voiceRecorder.isRecording {
                    GeometryReader { geo in
                        Circle()
                            .fill(
                                RadialGradient(gradient: Gradient(colors: [.red.opacity(0.6), .red.opacity(0.0)]), center: .center, startRadius: 0, endRadius: 400)
                            )
                            .blur(radius: 60)
                            .scaleEffect(1.0 + CGFloat(voiceRecorder.currentAmplitude) * 2.0)
                            .position(x: geo.size.width / 2, y: geo.size.height)
                            .animation(.easeOut(duration: 0.1), value: voiceRecorder.currentAmplitude)
                    }
                    .ignoresSafeArea()
                }
                
                VStack(spacing: 0) {
                    Spacer()
                    MotivationalMessageView()
                    Spacer()
                }
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    Spacer()
                    
                    // Record Button
                    Button(action: {
                        handleAudioRecording()
                    }) {
                        ZStack {
                            Circle()
                                .fill(voiceRecorder.isRecording ? Color.red : Theme.tint)
                                .frame(width: 80, height: 80)
                                .shadow(color: (voiceRecorder.isRecording ? Color.red : Theme.tint).opacity(0.3), radius: 10)
                            
                            Image(systemName: voiceRecorder.isRecording ? "stop.fill" : "mic.fill")
                                .font(.system(size: 35, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                    }
                    .accessibilityLabel(voiceRecorder.isRecording ? languageManager.t("Stop Recording") : languageManager.t("Start Recording"))
                    .accessibilityHint(voiceRecorder.isRecording ? languageManager.t("Stops the current audio recording and starts analysis") : languageManager.t("Starts a new audio recording"))
                    .accessibilityAddTraits(.isButton)
                    
                    Text(voiceRecorder.isRecording ? languageManager.t("Recording...") : languageManager.t("Tap to record"))
                        .font(.headline)
                        .padding()
                        .foregroundStyle(.gray)
                    
                    Spacer().frame(height: 50)
                }
                
                // Live Audio Visualizer
                if voiceRecorder.isRecording {
                    AudioVisualizer(amplitude: voiceRecorder.currentAmplitude)
                        .allowsHitTesting(false) // Pass touches through to the stop button
                }
                
                // Analysis Loading Screen
                if isAnalyzing {
                    ZStack {
                        Theme.background.ignoresSafeArea()
                        ParticleView(gravity: effectsState.gravity).ignoresSafeArea().opacity(0.5)
                        
                        VStack(spacing: 30) {
                            AnalysisLoadingView()
                                .frame(width: 200, height: 200)
                            
                            Text(languageManager.t("Analyzing Audio..."))
                                .font(.title3)
                                .fontWeight(.medium)
                                .foregroundStyle(Theme.primaryLabel)
                                .opacity(0.8)
                        }
                    }
                    .transition(.opacity)
                    .zIndex(2)
                }
            }
            .simultaneousGesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .global)
                    .onChanged { value in
                        effectsState.touchLocation = value.location
                    }
                    .onEnded { _ in
                        effectsState.touchLocation = .zero
                    }
            )
            .navigationTitle(languageManager.t("Voice"))
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Theme.background.opacity(0.8), for: .navigationBar)
            .navigationDestination(isPresented: $showPlayback) {
                if let recording = selectedRecording {
                    PlaybackView(voiceRecorder: voiceRecorder, storage: storage, recording: recording)
                }
            }
            .onAppear {
                voiceRecorder.requestPermission()
            }
            .overlay {
                if !voiceRecorder.microphonePermissionGranted {
                    PermissionDeniedView(
                        icon: "mic.fill",
                        title: "Microphone access required",
                        description: "Allow microphone access in settings to start recording your voice."
                    )
                } else if !voiceRecorder.speechPermissionGranted {
                    PermissionDeniedView(
                        icon: "waveform.path",
                        title: "Speech Recognition required",
                        description: "Echo uses speech recognition to analyze your clarity and pace. Please enable it in settings."
                    )
                }
            }
        }
        .background(Theme.background)
    }
    
    func handleAudioRecording() {
        if voiceRecorder.isRecording {
            HapticManager.shared.heavy() // Heavy haptic when stopping
            voiceRecorder.stopRecording()
            UIAccessibility.post(notification: .announcement, argument: languageManager.t("Recording stopped. Analyzing audio..."))
            withAnimation { isAnalyzing = true }
            
            Task { @MainActor in
                // Wait for file to be written
                try? await Task.sleep(nanoseconds: 500_000_000)
                
                if let recording = await voiceRecorder.getCurrentRecording() {
                    storage.saveRecording(recording)
                    selectedRecording = recording
                    
                    try? await Task.sleep(nanoseconds: 2 * 1_000_000_000)
                    
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
            HapticManager.shared.medium() // Medium haptic when starting
            voiceRecorder.startRecording()
            UIAccessibility.post(notification: .announcement, argument: languageManager.t("Recording started"))
        }
    }
}
