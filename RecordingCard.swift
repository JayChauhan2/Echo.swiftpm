import SwiftUI

struct RecordingCard: View {
    let recording: Recording
    let index: Int
    
    var body: some View {
        VStack(spacing: 8) {
            Group {
                if recording.isVideo {
                    Image(systemName: "video.fill")
                        .font(.system(size: 30))
                } else {
                    Image(systemName: "waveform")
                        .font(.system(size: 30))
                }
            }
            .foregroundStyle(
                Color(hue: (Double(index) * 0.1).truncatingRemainder(dividingBy: 1.0), saturation: 1.0, brightness: 1.0)
            )
            
            Text(recording.date, style: .date)
                .font(.caption2)
                .foregroundStyle(.white)
                .lineLimit(1)
            
            Text(formatDuration(recording.duration))
                .font(.caption2)
                .foregroundStyle(.gray)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .aspectRatio(1, contentMode: .fit)
        .background {
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.ultraThinMaterial)
                
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [.white.opacity(0.25), .white.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.5), .white.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
