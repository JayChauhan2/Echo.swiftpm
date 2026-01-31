import SwiftUI

struct AIAssistantView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var storage: RecordingStorage
    @StateObject private var progressViewModel: ProgressViewModel
    @EnvironmentObject var languageManager: LanguageManager
    
    @State private var messages: [ChatMessage] = []
    @State private var inputText: String = ""
    @State private var isTyping = false
    
    init(storage: RecordingStorage) {
        self.storage = storage
        _progressViewModel = StateObject(wrappedValue: ProgressViewModel(storage: storage))
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                // Chat History
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(messages) { message in
                                ChatBubble(message: message)
                            }
                            
                            if isTyping {
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(Color.gray)
                                        .frame(width: 6, height: 6)
                                        .opacity(0.5)
                                    Circle()
                                        .fill(Color.gray)
                                        .frame(width: 6, height: 6)
                                        .opacity(0.5)
                                    Circle()
                                        .fill(Color.gray)
                                        .frame(width: 6, height: 6)
                                        .opacity(0.5)
                                }
                                .padding(12)
                                .background(Color(.systemGray6))
                                .cornerRadius(16)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .padding()
                    }
                    .onChange(of: messages.count) { _ in
                        if let lastId = messages.last?.id {
                            withAnimation {
                                proxy.scrollTo(lastId, anchor: .bottom)
                            }
                        }
                    }
                }
                
                // Input Area
                HStack {
                    TextField(languageManager.t("Ask about your progress..."), text: $inputText)
                        .padding(10)
                        .background(Color(.systemGray6))
                        .cornerRadius(20)
                        .onSubmit {
                            sendMessage()
                        }
                    
                    Button(action: sendMessage) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(.blue)
                    }
                    .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding()
                .background(Color(.systemBackground))
            }
            .navigationTitle("Echo Assistant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                // Initial greeting
                if messages.isEmpty {
                    let greeting = ChatMessage(
                        role: .assistant,
                        content: languageManager.t("Hello! I'm your Echo Assistant. I can analyze your speaking data. Ask me about your confidence, practice usage, or hesitation trends!")
                    )
                    messages.append(greeting)
                }
                // Ensure stats are fresh
                progressViewModel.recalculateMetrics()
            }
        }
    }
    
    func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        
        let userMsg = ChatMessage(role: .user, content: text)
        messages.append(userMsg)
        inputText = ""
        isTyping = true
        
        // Simulate delay for on-device "thinking"
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let responseText = generateResponse(for: text)
            let aiMsg = ChatMessage(role: .assistant, content: responseText)
            withAnimation {
                isTyping = false
                messages.append(aiMsg)
            }
        }
    }
    
    func generateResponse(for query: String) -> String {
        let lowerQuery = query.lowercased()
        
        // Simple Intent Matching based on "stats" context
        
        if lowerQuery.contains("confidence") {
            let changeStr: String
            if progressViewModel.confidenceChange > 0 {
                changeStr = "improving by \(progressViewModel.confidenceChange)% this week"
            } else if progressViewModel.confidenceChange < 0 {
                changeStr = "down by \(abs(progressViewModel.confidenceChange))% this week"
            } else {
                changeStr = "steady"
            }
            return "Your current confidence score is \(progressViewModel.currentConfidence)%. You are \(changeStr). Keep practicing to boost your projection!"
        }
        
        if lowerQuery.contains("practice") || lowerQuery.contains("time") || lowerQuery.contains("day") {
            return "You've practiced for \(progressViewModel.practiceMinutesToday) minutes today against your goal of \(progressViewModel.practiceGoalMinutes) minutes. Every minute counts!"
        }
        
        if lowerQuery.contains("hesitation") || lowerQuery.contains("pause") {
            return "Regarding hesitations: \(progressViewModel.hesitationScore). Reducing pauses helps with flow state."
        }
        
        if lowerQuery.contains("word") || lowerQuery.contains("count") {
            return "You have spoken a total of \(progressViewModel.wordsPracticed) words across all your sessions. That's a lot of practice!"
        }
        
        if lowerQuery.contains("clarity") {
            return "Your clarity score is currently \(progressViewModel.clarityScore)%. " + (progressViewModel.clarityScore > 80 ? "You're speaking very clearly!" : "Try to articulate more precisely.")
        }
        
        if lowerQuery.contains("progress") || lowerQuery.contains("stats") || lowerQuery.contains("summary") {
            return "Here is your summary:\n• Confidence: \(progressViewModel.currentConfidence)%\n• Today's Practice: \(progressViewModel.practiceMinutesToday) min\n• Hesitation: \(progressViewModel.hesitationScore)\n\nYou're doing great!"
        }
        
        // Default
        return "I can help you analyze your speaking progress. Try asking: \"How is my confidence?\" or \"How much have I practiced today?\""
    }
}

struct ChatMessage: Identifiable {
    let id = UUID()
    let role: Role
    let content: String
    let date = Date()
    
    enum Role {
        case user
        case assistant
    }
}

struct ChatBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.role == .user {
                Spacer()
                Text(message.content)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(16)
                    .containerRelativeFrame(.horizontal, count: 5, span: 4, spacing: 0, alignment: .trailing)
            } else {
                VStack(alignment: .leading) {
                    Text(message.content)
                        .padding()
                        .background(Color(.systemGray5))
                        .foregroundColor(.primary)
                        .cornerRadius(16)
                }
                .containerRelativeFrame(.horizontal, count: 5, span: 4, spacing: 0, alignment: .leading)
                Spacer()
            }
        }
    }
}
