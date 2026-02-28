import SwiftUI
import AVFoundation
import Vision

class CameraManager: NSObject, ObservableObject {
    @Published var permissionGranted = false
    @Published var isRecording = false
    @Published var recordedDuration: TimeInterval = 0
    @Published var outputFileURL: URL?
    
    let session = AVCaptureSession()
    private let movieOutput = AVCaptureMovieFileOutput()
    private let videoOutput = AVCaptureVideoDataOutput()
    
    private var recordingStartTime: Date?
    private var timer: Timer?
    
    override init() {
        super.init()
        checkPermission()
    }
    
    func checkPermission() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            DispatchQueue.main.async {
                self.permissionGranted = true
            }
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.setupSession()
            }
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.permissionGranted = granted
                }
                if granted {
                    DispatchQueue.global(qos: .userInitiated).async {
                        self?.setupSession()
                    }
                }
            }
        case .denied, .restricted:
            DispatchQueue.main.async {
                self.permissionGranted = false
            }
        @unknown default:
            DispatchQueue.main.async {
                self.permissionGranted = false
            }
        }
    }
    
    private func setupSession() {
        session.beginConfiguration()
        session.sessionPreset = .high
        
        // Add Video Input
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else { return }
        guard let videoInput = try? AVCaptureDeviceInput(device: videoDevice) else { return }
        
        if session.canAddInput(videoInput) {
            session.addInput(videoInput)
        }
        
        // Add Audio Input
        if let audioDevice = AVCaptureDevice.default(for: .audio),
           let audioInput = try? AVCaptureDeviceInput(device: audioDevice) {
            if session.canAddInput(audioInput) {
                session.addInput(audioInput)
            }
        }
        
        // Add Movie Output
        if session.canAddOutput(movieOutput) {
            session.addOutput(movieOutput)
        }
        
        // Add Video Data Output (for analysis)
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
        }
        
        session.commitConfiguration()
        
        // Already on background thread
        self.session.startRunning()
    }
    
    func startRecording() {
        guard !isRecording else { return }
        
        // Create temp file
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("mov")
        
        // Ensure connection is active
        if let connection = movieOutput.connection(with: .video) {
             if connection.isVideoMirroringSupported {
                 connection.isVideoMirrored = true // Mirror front camera
             }
             if connection.isVideoOrientationSupported {
                 connection.videoOrientation = .portrait
             }
        }
        
        movieOutput.startRecording(to: tempURL, recordingDelegate: self)
        
        isRecording = true
        recordingStartTime = Date()
        recordedDuration = 0
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let startTime = self.recordingStartTime else { return }
            self.recordedDuration = Date().timeIntervalSince(startTime)
        }
    }
    
    func stopRecording() {
        guard isRecording else { return }
        
        movieOutput.stopRecording()
        isRecording = false
        timer?.invalidate()
        timer = nil
    }
    
    func setFrameDelegate(_ delegate: AVCaptureVideoDataOutputSampleBufferDelegate) {
        videoOutput.setSampleBufferDelegate(delegate, queue: DispatchQueue(label: "videoQueue"))
    }
}

extension CameraManager: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if let error = error {
            print("Error recording: \(error.localizedDescription)")
            return
        }
        
        // Move to Documents
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let filename = outputFileURL.lastPathComponent
        let destinationURL = documentsPath.appendingPathComponent(filename)
        
        do {
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            try FileManager.default.moveItem(at: outputFileURL, to: destinationURL)
            
            DispatchQueue.main.async {
                self.outputFileURL = destinationURL
            }
        } catch {
            print("Error moving file: \(error.localizedDescription)")
        }
    }
}
