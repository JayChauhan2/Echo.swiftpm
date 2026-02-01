import SwiftUI

struct RecordingCard: View {
    @EnvironmentObject var languageManager: LanguageManager
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
            
            Text(formatDate(recording.date))
                .font(.caption2)
                .foregroundStyle(Theme.primaryLabel)
                .lineLimit(1)
            
            Text(formatDuration(recording.duration))
                .font(.caption2)
                .foregroundStyle(.gray)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .aspectRatio(1, contentMode: .fit)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a" // e.g., "Jan 29, 2:30 PM"
        formatter.locale = languageManager.currentLocale
        return formatter.string(from: date)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
