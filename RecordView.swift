import SwiftUI

struct RecordView: View {
    @StateObject var voiceRecorder = VoiceRecorder()
    @ObservedObject var storage: RecordingStorage
    
    @State private var showPlayback = false
    @State private var isAnalyzing = false
    @State private var selectedRecording: Recording?
    @State private var touchLocation: CGPoint = .zero
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color.black.ignoresSafeArea()
                
                // Particle Visualization
                ParticleView(amplitude: voiceRecorder.currentAmplitude, touchLocation: touchLocation)
                    .ignoresSafeArea()
                
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
                        .padding(.bottom, 40)
                    
                    // Record Button
                    Button(action: {
                        handleAudioRecording()
                    }) {
                        Image(systemName: voiceRecorder.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 100, height: 100)
                            .foregroundColor(.red)
                    }
                    
                    Text(voiceRecorder.isRecording ? "Recording..." : "Tap to record")
                        .font(.headline)
                        .padding()
                        .foregroundStyle(.gray)
                    
                    Spacer().frame(height: 50)
                }
                
                // Live Audio Visualizer
                if voiceRecorder.isRecording {
                    AudioVisualizer(amplitude: voiceRecorder.currentAmplitude)
                }
                
                // Analysis Loading Screen
                if isAnalyzing {
                    ZStack {
                        Color.black.ignoresSafeArea()
                        ParticleView().ignoresSafeArea().opacity(0.5)
                        
                        VStack(spacing: 30) {
                            AnalysisLoadingView()
                                .frame(width: 200, height: 200)
                            
                            Text("Analyzing Audio...")
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
            .navigationTitle("Record")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $showPlayback) {
                if let recording = selectedRecording {
                    PlaybackView(voiceRecorder: voiceRecorder, storage: storage, recording: recording)
                }
            }
            .onAppear {
                voiceRecorder.requestPermission()
            }
        }
    }
    
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
}
