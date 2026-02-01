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
                    Circle()
                        .fill(
                            RadialGradient(gradient: Gradient(colors: [.red.opacity(0.6), .red.opacity(0.0)]), center: .center, startRadius: 0, endRadius: 400)
                        )
                        .blur(radius: 50)
                        .scaleEffect(1.0 + CGFloat(voiceRecorder.currentAmplitude) * 2.0)
                        .position(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height + 20)
                        .animation(.easeOut(duration: 0.1), value: voiceRecorder.currentAmplitude)
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
                        Image(systemName: voiceRecorder.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 100, height: 100)
                            .foregroundStyle(Theme.brandPrimary.gradient)
                    }
                    
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
                        Color.black.ignoresSafeArea()
                        ParticleView(gravity: effectsState.gravity).ignoresSafeArea().opacity(0.5)
                        
                        VStack(spacing: 30) {
                            AnalysisLoadingView()
                                .frame(width: 200, height: 200)
                            
                            Text(languageManager.t("Analyzing Audio..."))
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
        }
        .background(Theme.background)
    }
    
    func handleAudioRecording() {
        if voiceRecorder.isRecording {
            HapticManager.shared.heavy() // Heavy haptic when stopping
            voiceRecorder.stopRecording()
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
        }
    }
}
