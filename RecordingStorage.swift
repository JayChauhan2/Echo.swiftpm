import Foundation
import Combine

class RecordingStorage: ObservableObject {
    @Published var recordings: [Recording] = []
    
    private let userDefaultsKey = "SavedRecordings"
    private let recordingsDirectoryName = "Recordings"
    
    init() {
        createRecordingsDirectory()
        migrateFromUserDefaults()
        loadRecordings()
    }
    
    // MARK: - File System Management
    
    private var recordingsDirectory: URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent(recordingsDirectoryName)
    }
    
    private func createRecordingsDirectory() {
        if !FileManager.default.fileExists(atPath: recordingsDirectory.path) {
            try? FileManager.default.createDirectory(at: recordingsDirectory, withIntermediateDirectories: true)
        }
    }
    
    // MARK: - CRUD Operations
    
    func saveRecording(_ recording: Recording) {
        // Update in-memory
        recordings.insert(recording, at: 0)
        
        // Persist to disk asynchronously
        DispatchQueue.global(qos: .background).async { [weak self] in
            self?.saveToDisk(recording)
        }
    }
    
    func deleteRecording(_ recording: Recording) {
        // Update in-memory
        recordings.removeAll { $0.id == recording.id }
        
        // Delete from disk asynchronously
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            
            // 1. Delete the metadata JSON
            let jsonURL = self.recordingsDirectory.appendingPathComponent("\(recording.id.uuidString).json")
            try? FileManager.default.removeItem(at: jsonURL)
            
            // 2. Delete the actual audio file
            // Note: filename might not be a full path, usually just "filename.m4a"
            // We assume audio files are in the Documents root (legacy) or we should move them too.
            // For now, let's look in Document Directory root as per original app behavior
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let audioURL = documentsPath.appendingPathComponent(recording.filename)
            try? FileManager.default.removeItem(at: audioURL)
        }
    }
    
    // MARK: - Persistence Logic
    
    private func saveToDisk(_ recording: Recording) {
        let fileURL = recordingsDirectory.appendingPathComponent("\(recording.id.uuidString).json")
        do {
            let data = try JSONEncoder().encode(recording)
            try data.write(to: fileURL)
        } catch {
            print("Failed to save recording JSON: \(error)")
        }
    }
    
    private func loadRecordings() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let fileManager = FileManager.default
            guard let files = try? fileManager.contentsOfDirectory(at: self.recordingsDirectory, includingPropertiesForKeys: nil) else { return }
            
            let jsonFiles = files.filter { $0.pathExtension == "json" }
            
            var loadedRecordings: [Recording] = []
            
            for url in jsonFiles {
                if let data = try? Data(contentsOf: url),
                   let recording = try? JSONDecoder().decode(Recording.self, from: data) {
                    loadedRecordings.append(recording)
                }
            }
            
            // Sort by date descending
            loadedRecordings.sort { $0.date > $1.date }
            
            DispatchQueue.main.async {
                self.recordings = loadedRecordings
            }
        }
    }
    
    // MARK: - Migration
    
    private func migrateFromUserDefaults() {
        // Check if we have data in UserDefaults
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let oldRecordings = try? JSONDecoder().decode([Recording].self, from: data) else {
            return
        }
        
        if oldRecordings.isEmpty { return }
        
        print("Migrating \(oldRecordings.count) recordings from UserDefaults...")
        
        // Save each to disk
        for recording in oldRecordings {
            // Check if already exists on disk to avoid re-saving (basic check)
            let fileURL = recordingsDirectory.appendingPathComponent("\(recording.id.uuidString).json")
            if !FileManager.default.fileExists(atPath: fileURL.path) {
                saveToDisk(recording)
            }
        }
        
        // Clear UserDefaults
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
        print("Migration complete. UserDefaults cleared.")
    }
}
