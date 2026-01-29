import Foundation
import Speech
import AVFoundation

class AudioAnalyzer: NSObject {
    
    // MARK: - Analysis Methods
    
    // MARK: - Analysis Methods
    
    func analyze(url: URL) async throws -> AudioAnalysisResult {
        // 1. Transcription & Timing (Offline)
        let (transcription, segments, speechRate, pauseFreq) = try await analyzeSpeech(url: url)
        
        // 2. Audio Signal Analysis
        let (volumeStability, _) = try analyzeAudioSignal(url: url)
        
        // 3. Segment Analysis & Heuristic Inference
        let analysisSegments = analyzeSegments(
            segments: segments,
            totalDuration: segments.last?.timestamp ?? 0 + (segments.last?.duration ?? 0),
            volumeStability: volumeStability, // Passing global stability for now as a fallback/baseline
            globalSpeechRate: speechRate
        )
        
        // Determine global state based on dominant segment state or weighted average
        // For simplicity, let's keep the previous logic but maybe refine it
        let state = inferGlobalState(segments: analysisSegments, globalRate: speechRate, globalStability: volumeStability, globalPauseFreq: pauseFreq)
        
        // Calculate a simple confidence score based on the state
        let confidenceScore: Double
        switch state {
        case .confident: confidenceScore = 0.9
        case .grounded: confidenceScore = 0.85
        case .neutral: confidenceScore = 0.7
        case .hesitant: confidenceScore = 0.4
        case .unclear: confidenceScore = 0.2
        }
        
        return AudioAnalysisResult(
            speechRate: speechRate,
            pauseFrequency: pauseFreq,
            volumeStability: volumeStability,
            communicationState: state,
            transcription: transcription,
            confidenceScore: confidenceScore,
            segments: analysisSegments
        )
    }
    
    // MARK: - Private Helpers
    
    private func analyzeSegments(segments: [SFTranscriptionSegment], totalDuration: TimeInterval, volumeStability: Double, globalSpeechRate: Double) -> [AnalysisSegment] {
        var analysisSegments: [AnalysisSegment] = []
        
        // Group words into phrases based on pauses
        var currentPhrase: [SFTranscriptionSegment] = []
        var lastEndTime: TimeInterval = 0
        
        for segment in segments {
            let gap = segment.timestamp - lastEndTime
            
            if gap > 0.5 && !currentPhrase.isEmpty {
                // End of phrase, analyze it
                if let phraseSegment = createAnalysisSegment(from: currentPhrase, previousEndTime: lastEndTime - gap, globalStability: volumeStability) {
                    analysisSegments.append(phraseSegment)
                }
                currentPhrase = []
            }
            
            currentPhrase.append(segment)
            lastEndTime = segment.timestamp + segment.duration
        }
        
        // Capture last phrase
        if !currentPhrase.isEmpty {
            if let phraseSegment = createAnalysisSegment(from: currentPhrase, previousEndTime: lastEndTime, globalStability: volumeStability) {
                analysisSegments.append(phraseSegment)
            }
        }
        
        // Fill in gaps with "Neutral" Segments (or Silence)
        // For simplicity, let's just return the active segments. PlaybackView can handle gaps (default gray).
        return analysisSegments
    }
    
    private func createAnalysisSegment(from words: [SFTranscriptionSegment], previousEndTime: TimeInterval, globalStability: Double) -> AnalysisSegment? {
        guard let first = words.first, let last = words.last else { return nil }
        
        let startTime = first.timestamp
        let endTime = last.timestamp + last.duration
        let duration = endTime - startTime
        
        // 1. Calculate Local Metrics
        let wordCount = words.count
        let localWPM = Double(wordCount) / (duration / 60.0)
        
        // Average confidence of words in this segment
        let avgConfidence = words.reduce(0.0) { $0 + Double($1.confidence) } / Double(wordCount)
        
        // Detect hesitation within the phrase (gaps between words < 0.5s but noticeable)
        var hesitationCount = 0
        for i in 0..<words.count - 1 {
            let gap = words[i+1].timestamp - (words[i].timestamp + words[i].duration)
            if gap > 0.2 { // Small gaps indicating hesitation
                hesitationCount += 1
            }
        }
        let isHesitantPhrase = hesitationCount > 1
        
        // 2. Apply Heuristics
        let state: CommunicationState
        
        // Confident: Steady volume (global proxy), fluent (no internal hesitations), proper pace
        // Steady volume + low pause rate
        if globalStability > 0.6 && !isHesitantPhrase && localWPM > 110 && avgConfidence > 0.6 {
            state = .confident
        }
        // Hesitant: Frequent pauses + fillers (simulated by small gaps)
        else if isHesitantPhrase || (localWPM < 90 && wordCount > 2) {
            state = .hesitant
        }
        // Unclear: Long speech but low clarity words
        else if duration > 3.0 && avgConfidence < 0.4 {
            state = .unclear
        }
        // Grounded: Calm pace + clear phrasing
        else if localWPM >= 90 && localWPM <= 130 && avgConfidence > 0.8 && !isHesitantPhrase {
            state = .grounded
        }
        else {
            state = .neutral
        }
        
        return AnalysisSegment(startTime: startTime, endTime: endTime, state: state)
    }
    
    private func inferGlobalState(segments: [AnalysisSegment], globalRate: Double, globalStability: Double, globalPauseFreq: Double) -> CommunicationState {
        // If majority of segments are a certain state, adopt it
        let counts = segments.reduce(into: [CommunicationState: Int]()) { $0[$1.state, default: 0] += 1 }
        
        if let (maxState, count) = counts.max(by: { $0.value < $1.value }) {
            if Double(count) / Double(segments.count) > 0.5 {
                return maxState
            }
        }
        
        // Fallback to original global heuristics if no dominant segment state
        if globalStability > 0.6 && globalPauseFreq < 8.0 && globalRate > 100 && globalRate < 160 {
            return .confident
        }
        if globalPauseFreq > 12 {
            return .hesitant
        }
        if globalRate < 80 || globalRate > 200 {
            return .unclear
        }
        return .neutral
    }

    private func analyzeSpeech(url: URL) async throws -> (String, [SFTranscriptionSegment], Double, Double) {
        return try await withCheckedThrowingContinuation { continuation in
            let recognizer = SFSpeechRecognizer()
            
            // CRITICAL: Ensure offline capability
            if recognizer?.isAvailable == false {
                continuation.resume(throwing: NSError(domain: "AudioAnalyzer", code: 1, userInfo: [NSLocalizedDescriptionKey: "Speech recognizer not available"]))
                return
            }
            
            let request = SFSpeechURLRecognitionRequest(url: url)
            request.shouldReportPartialResults = false
            request.requiresOnDeviceRecognition = true // Force offline recognition
            
            recognizer?.recognitionTask(with: request) { result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let result = result, result.isFinal else { return }
                
                let transcription = result.bestTranscription.formattedString
                let segments = result.bestTranscription.segments
                let duration = segments.last?.timestamp ?? 0 + (segments.last?.duration ?? 0)
                
                // Calculate Speech Rate (WPM)
                // Avoid division by zero
                let durationInMinutes = max(duration / 60.0, 0.01)
                let wpm = Double(segments.count) / durationInMinutes
                
                // Calculate Pause Frequency
                // A "pause" is a significant gap between segments. Let's say > 0.5s
                var pauseCount = 0
                for i in 0..<segments.count - 1 {
                    let endCurrent = segments[i].timestamp + segments[i].duration
                    let startNext = segments[i+1].timestamp
                    if startNext - endCurrent > 0.5 {
                        pauseCount += 1
                    }
                }
                let pausesPerMinute = Double(pauseCount) / durationInMinutes
                
                continuation.resume(returning: (transcription, segments, wpm, pausesPerMinute))
            }
        }
    }
    
    private func analyzeAudioSignal(url: URL) throws -> (Double, Double) {
        let file = try AVAudioFile(forReading: url)
        
        guard let format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: file.fileFormat.sampleRate, channels: 1, interleaved: false),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(file.length)) else {
            return (0, 0)
        }
        
        try file.read(into: buffer)
        
        guard let channelData = buffer.floatChannelData?[0] else { return (0, 0) }
        let frames = Int(buffer.frameLength)
        
        // Calculate RMS in chunks to see stability
        let chunkSize = 4096 // arbitrary
        var rmsValues: [Float] = []
        
        for i in stride(from: 0, to: frames, by: chunkSize) {
            let end = min(i + chunkSize, frames)
            let length = end - i
            var sum: Float = 0
            for j in 0..<length {
                let sample = channelData[i + j]
                sum += sample * sample
            }
            let rms = sqrt(sum / Float(length))
            rmsValues.append(rms)
        }
        
        // Calculate Variance of RMS - Lower variance means more stable volume
        let meanRMS = rmsValues.reduce(0, +) / Float(rmsValues.count)
        let variance = rmsValues.map { pow($0 - meanRMS, 2) }.reduce(0, +) / Float(rmsValues.count)
        
        // Normalize stability: 1.0 is stable, 0.0 is unstable
        // Variance depends on volume, but let's do a simple inverse mapping
        // A high variance might be 0.01 for speech?
        // Let's just return raw variance for now, or invert it carefully?
        // Better yet: "Stability" = 1 / (1 + variance * 1000)
        let stability = 1.0 / (1.0 + Double(variance) * 1000.0)
        
        return (stability, Double(meanRMS))
    }
}
