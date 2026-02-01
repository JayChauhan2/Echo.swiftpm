import SwiftUI

struct LibraryView: View {
    @ObservedObject var storage: RecordingStorage
    // We need a voiceRecorder instance to pass to PlaybackView for audio playback capability
    @StateObject var playbackVoiceRecorder = VoiceRecorder()
    @EnvironmentObject var effectsState: GlobalEffectsState
    @EnvironmentObject var languageManager: LanguageManager
    
    @State private var isSelectionMode = false
    @State private var selectedRecordingIDs = Set<UUID>()
    @State private var showBulkDeleteAlert = false
    @State private var selectedRecording: Recording?
    @State private var showPlayback = false
    @State private var recordingToDelete: Recording?
    @State private var showDeleteAlert = false
    @State private var showAI = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background - Remove solid color to show Global Particles
                // Background - Remove solid color to show Global Particles
                // Theme background is handled on the NavigationStack container
                
                ParticleView(amplitude: effectsState.amplitude, touchLocation: effectsState.touchLocation, gravity: effectsState.gravity)
                    .ignoresSafeArea()
                
                // Ensure amplitude is reset when entering library
                Color.clear
                    .onAppear {
                        effectsState.amplitude = 0.0
                    }
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        if storage.recordings.isEmpty {
                            VStack(spacing: 20) {
                                Image(systemName: "books.vertical")
                                    .font(.system(size: 60))
                                    .foregroundStyle(Color.secondary)
                                
                                Text(languageManager.t("Your library is empty"))
                                    .font(.title3)
                                    .foregroundStyle(Color.secondary)
                                
                                Text(languageManager.t("Recordings you save will appear here"))
                                    .font(.subheadline)
                                    .foregroundStyle(Color.secondary.opacity(0.8))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 100)
                        } else {
                            LazyVGrid(columns: [
                                GridItem(.adaptive(minimum: 100), spacing: 15) // Adaptive for dynamic type/screens
                            ], spacing: 15) {
                                ForEach(Array(storage.recordings.enumerated()), id: \.element.id) { index, recording in
                                    Button(action: {
                                        HapticManager.shared.light() // Light haptic for selection
                                        if isSelectionMode {
                                            if selectedRecordingIDs.contains(recording.id) {
                                                selectedRecordingIDs.remove(recording.id)
                                            } else {
                                                selectedRecordingIDs.insert(recording.id)
                                            }
                                        } else {
                                            selectedRecording = recording
                                            if !recording.isVideo {
                                                playbackVoiceRecorder.loadRecording(recording)
                                            }
                                            showPlayback = true
                                        }
                                    }) {
                                        ZStack(alignment: .bottomTrailing) {
                                            RecordingCard(recording: recording, index: index)
                                                .opacity(isSelectionMode && !selectedRecordingIDs.contains(recording.id) ? 0.6 : 1.0)
                                            
                                            if isSelectionMode {
                                                Image(systemName: selectedRecordingIDs.contains(recording.id) ? "checkmark.circle.fill" : "circle")
                                                    .font(.title2)
                                                    .foregroundStyle(selectedRecordingIDs.contains(recording.id) ? Theme.tint : .white)
                                                    .padding(8)
                                                    .background(Circle().fill(Color.black.opacity(0.5)))
                                                    .padding(6)
                                            }
                                        }
                                    }
                                    .contextMenu {
                                        if !isSelectionMode { // Disable context menu in selection mode
                                            Button(role: .destructive) {
                                                HapticManager.shared.warning() // Warning haptic for delete
                                                recordingToDelete = recording
                                                showDeleteAlert = true
                                            } label: {
                                                Label(languageManager.t("Delete"), systemImage: "trash")
                                            }
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
                        if !isSelectionMode { // Disable particles interaction in selection mode to avoid confusion
                            effectsState.touchLocation = value.location
                        }
                    }
                    .onEnded { _ in
                        effectsState.touchLocation = .zero
                    }
            )
            .navigationTitle(languageManager.t("Library"))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if !isSelectionMode {
                        Button(action: {
                            HapticManager.shared.light()
                            showAI = true
                        }) {
                            Image(systemName: "sparkles.rectangle.stack")
                                .font(.body)
                                .foregroundStyle(Theme.tint)
                        }
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    if isSelectionMode {
                         Button(languageManager.t("Cancel")) {
                             HapticManager.shared.light()
                             isSelectionMode = false
                             selectedRecordingIDs.removeAll()
                         }
                         .tint(Theme.brandPrimary)
                    } else {
                        Button(languageManager.t("Select")) {
                            HapticManager.shared.light()
                            isSelectionMode = true
                        }
                    }
                }
                
                ToolbarItem(placement: .topBarLeading) {
                    if isSelectionMode && !selectedRecordingIDs.isEmpty {
                        Button(role: .destructive) {
                             HapticManager.shared.warning()
                             showBulkDeleteAlert = true
                        } label: {
                            Text("\(languageManager.t("Delete")) (\(selectedRecordingIDs.count))")
                                .foregroundStyle(.red)
                        }
                    }
                }
            }
            .navigationDestination(isPresented: $showPlayback) {
                if let recording = selectedRecording {
                    PlaybackView(voiceRecorder: playbackVoiceRecorder, storage: storage, recording: recording)
                }
            }
            .sheet(isPresented: $showAI) {
                AIAssistantView(storage: storage)
            }
        }
        .background(Theme.background)
        .alert(languageManager.t("Delete Selection"), isPresented: $showBulkDeleteAlert) {
            Button(languageManager.t("Cancel"), role: .cancel) { }
            Button(languageManager.t("Delete"), role: .destructive) {
                HapticManager.shared.error()
                // Bulk delete
                for id in selectedRecordingIDs {
                    if let recording = storage.recordings.first(where: { $0.id == id }) {
                        storage.deleteRecording(recording)
                    }
                }
                isSelectionMode = false
                selectedRecordingIDs.removeAll()
            }
        } message: {
            Text(languageManager.t("Are you sure you want to delete these recordings?"))
        }
        .alert(languageManager.t("Delete Recording"), isPresented: $showDeleteAlert, presenting: recordingToDelete) { recording in
            Button(languageManager.t("Cancel"), role: .cancel) { 
                HapticManager.shared.light() // Light haptic for cancel
            }
                .tint(Theme.brandPrimary)
            Button(languageManager.t("Delete"), role: .destructive) {
                HapticManager.shared.error() // Error haptic for deletion
                storage.deleteRecording(recording)
            }
        } message: { recording in
            Text("Are you sure you want to delete \"\(getRecordingName(recording))\"?") // Keeping complex string partial for now
        }
    }
    
    private func getRecordingName(_ recording: Recording) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a" // e.g., "Jan 29, 2:30 PM"
        formatter.locale = languageManager.currentLocale
        return formatter.string(from: recording.date)
    }
}
