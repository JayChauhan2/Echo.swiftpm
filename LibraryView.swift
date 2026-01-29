import SwiftUI

struct LibraryView: View {
    @ObservedObject var storage: RecordingStorage
    // We need a voiceRecorder instance to pass to PlaybackView for audio playback capability
    @StateObject var playbackVoiceRecorder = VoiceRecorder()
    @EnvironmentObject var effectsState: GlobalEffectsState
    
    @State private var selectedRecording: Recording?
    @State private var showPlayback = false
    @State private var recordingToDelete: Recording?
    @State private var showDeleteAlert = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background - Remove solid color to show Global Particles
                Color.black.ignoresSafeArea()
                
                ParticleView(amplitude: effectsState.amplitude, touchLocation: effectsState.touchLocation, gravity: effectsState.gravity)
                    .ignoresSafeArea()
                
                // Ensure amplitude is reset when entering library
                Color.clear
                    .onAppear {
                        effectsState.amplitude = 0.0
                    }
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Library")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundStyle(.red)
                            .padding(.top)
                            .padding(.horizontal)
                        
                        if storage.recordings.isEmpty {
                            VStack(spacing: 20) {
                                Image(systemName: "books.vertical")
                                    .font(.system(size: 60))
                                    .foregroundStyle(.gray.opacity(0.5))
                                
                                Text("Your library is empty")
                                    .font(.title3)
                                    .foregroundStyle(.gray)
                                
                                Text("Recordings you save will appear here")
                                    .font(.subheadline)
                                    .foregroundStyle(.gray.opacity(0.8))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 100)
                        } else {
                            LazyVGrid(columns: [
                                GridItem(.flexible(), spacing: 15),
                                GridItem(.flexible(), spacing: 15),
                                GridItem(.flexible(), spacing: 15)
                            ], spacing: 15) {
                                ForEach(Array(storage.recordings.enumerated()), id: \.element.id) { index, recording in
                                    Button(action: {
                                        HapticManager.shared.light() // Light haptic for selection
                                        selectedRecording = recording
                                        if !recording.isVideo {
                                            playbackVoiceRecorder.loadRecording(recording)
                                        }
                                        showPlayback = true
                                    }) {
                                        RecordingCard(recording: recording, index: index)
                                    }
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            HapticManager.shared.warning() // Warning haptic for delete
                                            recordingToDelete = recording
                                            showDeleteAlert = true
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 100)
                        }
                    }
                }
                .scrollContentBackground(.hidden)
                .background(Color.clear)
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
            .navigationDestination(isPresented: $showPlayback) {
                if let recording = selectedRecording {
                    PlaybackView(voiceRecorder: playbackVoiceRecorder, storage: storage, recording: recording)
                }
            }
        }
        .background(Color.clear)
        .alert("Delete Recording", isPresented: $showDeleteAlert, presenting: recordingToDelete) { recording in
            Button("Cancel", role: .cancel) { 
                HapticManager.shared.light() // Light haptic for cancel
            }
                .tint(.white)
            Button("Delete", role: .destructive) {
                HapticManager.shared.error() // Error haptic for deletion
                storage.deleteRecording(recording)
            }
            .tint(.red)
        } message: { recording in
            Text("Are you sure you want to delete \"\(getRecordingName(recording))\"?")
        }
    }
    
    private func getRecordingName(_ recording: Recording) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a" // e.g., "Jan 29, 2:30 PM"
        return formatter.string(from: recording.date)
    }
}
