import SwiftUI

struct CameraRecordView: View {
    @StateObject var cameraManager = CameraManager()
    @StateObject var videoAnalyzer = VideoAnalyzer()
    @ObservedObject var storage: RecordingStorage
    
    @State private var showPlayback = false
    @State private var isAnalyzing = false
    @State private var selectedRecording: Recording?
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
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
                        Text("Camera access required")
                            .font(.headline)
                            .foregroundStyle(.gray)
                        Button("Open Settings") {
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
                    Spacer()
                    
                    if cameraManager.isRecording {
                        // Camera Feedback Overlay
                        Text(videoAnalyzer.currentPresence.rawValue)
                            .font(.headline)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(.ultraThinMaterial)
                            .cornerRadius(20)
                            .foregroundStyle(.white)
                            .padding(.bottom, 20)
                    }
                    
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
                    
                    Text(cameraManager.isRecording ? "Recording Presence..." : "Tap to record")
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
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Camera")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(.red)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color.clear, for: .navigationBar)
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
                        samples: [], // No audio waveform
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
                    withAnimation { isAnalyzing = false }
                }
            }
        } else {
            videoAnalyzer.startAnalysis()
            cameraManager.startRecording()
        }
    }
}
