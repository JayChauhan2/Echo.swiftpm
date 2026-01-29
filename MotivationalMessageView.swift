import SwiftUI

struct MotivationalMessageView: View {
    enum MessageType {
        case audio
        case camera
    }
    
    let type: MessageType
    @State private var fullMessage: String = ""
    
    private let audioMessages = [
        "Ready to Rock Today? 🎸",
        "Time to shine! ✨",
        "Capture your brilliant thoughts! 💡",
        "Let's make some magic! 🪄",
        "Your voice matters! 🎙️",
        "Speak your mind! 🧠",
        "Go for it! 🚀",
        "Unleash your creativity! 🎨",
        "Today is a great day! ☀️",
        "Record your genius! ⚡️"
    ]
    
    private let cameraMessages = [
        "Smile for the camera! 📸",
        "Show your confidence! 💪",
        "Eyes on the prize! 👀",
        "You look great! ✨",
        "Stand tall! 🦒",
        "Ready for your closeup? 🎬",
        "Project your presence! 🌟",
        "Share your vision! 👁️",
        "Be yourself! 🌈",
        "Lights, Camera, Action! 🎥"
    ]
    
    init(type: MessageType = .audio) {
        self.type = type
    }
    
    var messages: [String] {
        type == .camera ? cameraMessages : audioMessages
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Text(textPart)
                .font(.title2) // Bigger text
                .fontWeight(.bold) // Bolder for better visibility
                .foregroundStyle(.white)
            
            WigglingEmojiView(emoji: emojiPart)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 24)
        .onAppear {
            fullMessage = messages.randomElement() ?? messages[0]
        }
        // Change message on tap
        .onTapGesture {
            withAnimation {
                fullMessage = messages.randomElement() ?? messages[0]
            }
        }
    }
    
    var textPart: String {
        guard !fullMessage.isEmpty else { return "" }
        // Dropping the last character (emoji)
        return String(fullMessage.dropLast())
    }
    
    var emojiPart: String {
        guard !fullMessage.isEmpty else { return "" }
        return String(fullMessage.suffix(1))
    }
}

struct WigglingEmojiView: View {
    let emoji: String
    @State private var rotation: Double = 0
    let timer = Timer.publish(every: 4, on: .main, in: .common).autoconnect()
    
    var body: some View {
        Text(emoji)
            .font(.title) // Bigger emoji
            .rotationEffect(.degrees(rotation))
            .onReceive(timer) { _ in
                // Use a Task to sequence the wiggle animation manually
                // This ensures we start at 0 and definitely end at 0, preventing jitter
                Task { @MainActor in
                    withAnimation(.easeInOut(duration: 0.2)) { rotation = 10 }
                    try? await Task.sleep(nanoseconds: 200_000_000)
                    
                    withAnimation(.easeInOut(duration: 0.2)) { rotation = -10 }
                    try? await Task.sleep(nanoseconds: 200_000_000)
                    
                    withAnimation(.easeInOut(duration: 0.2)) { rotation = 5 }
                    try? await Task.sleep(nanoseconds: 200_000_000)
                    
                    withAnimation(.easeInOut(duration: 0.2)) { rotation = 0 }
                }
            }
    }
}
