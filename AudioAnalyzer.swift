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
        
        // 3. Segment Analysis & Heuristic Inference (Granular)
        let analysisSegments = analyzeGranularSegments(
            segments: segments,
            transcription: transcription,
            volumeStability: volumeStability
        )
        
        // Determine global state based on weighted duration of states
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
    
    private func analyzeGranularSegments(segments: [SFTranscriptionSegment], transcription: String, volumeStability: Double) -> [AnalysisSegment] {
        var analysisSegments: [AnalysisSegment] = []
        var currentPhrase: [SFTranscriptionSegment] = []
        var lastEndTime: TimeInterval = 0.0
        
        // Filler words list (lowercase for comparison)
        let fillers: Set<String> = ["um", "uh", "hmm", "er", "ah", "like"]
        
        var searchRange = transcription.startIndex..<transcription.endIndex
        
        for (index, segment) in segments.enumerated() {
            let word = segment.substring.lowercased().trimmingCharacters(in: .punctuationCharacters)
            let gap = segment.timestamp - lastEndTime
            
            // Search for this word in the transcription to check for preceeding punctuation
            var followsPunctuation = false
            if let range = transcription.range(of: segment.substring, options: .caseInsensitive, range: searchRange) {
                // Check characters before this word (in the gap)
                let preGap = transcription[searchRange.lowerBound..<range.lowerBound]
                if preGap.contains(".") || preGap.contains(",") || preGap.contains("?") || preGap.contains("!") || preGap.contains(":") || preGap.contains(";") {
                    followsPunctuation = true
                }
                // Advance search range
                if range.upperBound < transcription.endIndex {
                    searchRange = range.upperBound..<transcription.endIndex
                }
            }
            
            // 1. Check for significant pause/gap
            if gap > 0.5 {
                // Analyze pending phrase first
                if !currentPhrase.isEmpty {
                    if let phraseSegment = analyzePhrase(currentPhrase, volumeStability: volumeStability) {
                        analysisSegments.append(phraseSegment)
                    }
                    currentPhrase = []
                }
                
                // Smart "AI" Decision:
                // If the gap follows punctuation (sentence break), it is a Natural Pause (Neutral/Gray).
                // If it does NOT follow punctuation (mid-sentence), it is Hesitant (Orange).
                if !followsPunctuation {
                     // Add the gap as a Hesitant segment
                    analysisSegments.append(AnalysisSegment(startTime: lastEndTime, endTime: segment.timestamp, state: .hesitant))
                }
                // Else: Neutral/Gray (implicitly handled by lack of segment)
            }
            
            // 2. Check for explicit filler word
            if fillers.contains(word) {
                // Flush pending phrase
                if !currentPhrase.isEmpty {
                    if let phraseSegment = analyzePhrase(currentPhrase, volumeStability: volumeStability) {
                        analysisSegments.append(phraseSegment)
                    }
                    currentPhrase = []
                }
                
                // Add Hesitant segment for the filler
                let start = segment.timestamp
                let end = segment.timestamp + segment.duration
                analysisSegments.append(AnalysisSegment(startTime: start, endTime: end, state: .hesitant))
                
                lastEndTime = end
                continue
            }
            
            currentPhrase.append(segment)
            lastEndTime = segment.timestamp + segment.duration
            
            // Flush at end
            if index == segments.count - 1 {
                if let phraseSegment = analyzePhrase(currentPhrase, volumeStability: volumeStability) {
                    analysisSegments.append(phraseSegment)
                }
            }
        }
        
        return analysisSegments
    }
    
    private func analyzePhrase(_ words: [SFTranscriptionSegment], volumeStability: Double) -> AnalysisSegment? {
        guard let first = words.first, let last = words.last else { return nil }
        
        let startTime = first.timestamp
        let endTime = last.timestamp + last.duration
        let duration = endTime - startTime
        
        // Skip extremely short artifacts
        if duration < 0.1 { return nil }
        
        let wordCount = words.count
        // Avoid division by zero
        let durationMin = max(duration / 60.0, 0.001)
        let localWPM = Double(wordCount) / durationMin
        
        let avgConfidence = words.reduce(0.0) { $0 + Double($1.confidence) } / Double(wordCount)
        
        let state: CommunicationState
        
        // --- Per-Clause Heuristics ---
        
        // Unclear: Very low confidence regardless of speed
        if avgConfidence < 0.4 {
            state = .unclear
        }
        // Grounded: Calm, steady pace, high clarity
        // WPM Range: 90 - 130
        else if localWPM >= 80 && localWPM <= 140 && avgConfidence > 0.8 {
            state = .grounded
        }
        // Confident: Faster but clear, or just solid stats
        // WPM Range: 130 - 180 (or just generally high confidence + stability)
        else if (localWPM > 130 && localWPM < 190 && avgConfidence > 0.7) || (avgConfidence > 0.9 && volumeStability > 0.5) {
            state = .confident
        }
        // Hesitant Check for whole phrase (if very slow)
        else if localWPM < 70 && wordCount > 2 {
            state = .hesitant
        }
        else {
            state = .neutral
        }
        
        return AnalysisSegment(startTime: startTime, endTime: endTime, state: state)
    }
    
    private func inferGlobalState(segments: [AnalysisSegment], globalRate: Double, globalStability: Double, globalPauseFreq: Double) -> CommunicationState {
        // Calculate total duration for each state
        var durations: [CommunicationState: TimeInterval] = [
            .confident: 0,
            .grounded: 0,
            .hesitant: 0,
            .unclear: 0,
            .neutral: 0
        ]
        
        for segment in segments {
            let dur = segment.endTime - segment.startTime
            durations[segment.state, default: 0] += dur
        }
        
        // Find state with max duration
        let maxDurationState = durations.max(by: { $0.value < $1.value })?.key
        
        // If dominant state has significant presence (> 30% of time?), use it.
        // Or specific overrides: if hesitation is high (>20%), maybe flag as hesitant overall?
        
        let totalTime = segments.last?.endTime ?? 1.0
        
        if let dominant = maxDurationState, durations[dominant]! > (totalTime * 0.4) {
            return dominant
        }
        
        // Fallback to original global heuristics if no clear dominant segment state
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
