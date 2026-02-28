import SwiftUI
import NaturalLanguage

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
                    
                    Button(action: {
                        HapticManager.shared.light()
                        sendMessage()
                    }) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(.red)
                    }
                    .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding()
                .background(Color(.systemBackground))
            }
            .navigationTitle(languageManager.t("Echo Assistant"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(languageManager.t("Done")) {
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
                HapticManager.shared.success() // Success haptic when AI responds
                isTyping = false
                messages.append(aiMsg)
            }
        }
    }
    
    func generateResponse(for query: String) -> String {
        // Advanced Intent Analysis using NaturalLanguage
        let intent = analyzeIntent(from: query)
        
        switch intent {
        case .checkConfidence:
            let changeStr: String
            if progressViewModel.confidenceChange > 0 {
                changeStr = "\(languageManager.t("improving by")) \(progressViewModel.confidenceChange)% \(languageManager.t("this week"))"
            } else if progressViewModel.confidenceChange < 0 {
                changeStr = "\(languageManager.t("down by")) \(abs(progressViewModel.confidenceChange))% \(languageManager.t("this week"))"
            } else {
                changeStr = languageManager.t("steady")
            }
            return "\(languageManager.t("Your current confidence score is")) \(progressViewModel.currentConfidence)%. \(languageManager.t("You are")) \(changeStr). \(languageManager.t("Keep practicing to boost your projection!"))"
            
        case .checkPractice:
            return "\(languageManager.t("You've practiced for")) \(progressViewModel.practiceMinutesToday) \(languageManager.t("minutes today against your goal of")) \(progressViewModel.practiceGoalMinutes) \(languageManager.t("minutes. Every minute counts!"))"
            
        case .checkHesitation:
            return "\(languageManager.t("Regarding hesitations:")) \(progressViewModel.hesitationScore). \(languageManager.t("Reducing pauses helps with flow state."))"
            
        case .checkWords:
            return "\(languageManager.t("You have spoken a total of")) \(progressViewModel.wordsPracticed) \(languageManager.t("words across all your sessions. That's a lot of practice!"))"
            
        case .checkClarity:
            let advice = progressViewModel.clarityScore > 80 ? languageManager.t("You're speaking very clearly!") : languageManager.t("Try to articulate more precisely.")
            return "\(languageManager.t("Your clarity score is currently")) \(progressViewModel.clarityScore)%. \(advice)"
            
        case .checkSummary:
            return "\(languageManager.t("Here is your summary:"))\n• \(languageManager.t("Confidence")): \(progressViewModel.currentConfidence)%\n• \(languageManager.t("Today's Practice:")) \(progressViewModel.practiceMinutesToday) min\n• \(languageManager.t("Hesitation:")) \(progressViewModel.hesitationScore)\n\n\(languageManager.t("You're doing great!"))"
            
        case .greeting:
             return languageManager.t("Hello! I'm ready to help you analyze your speaking.")
            
        case .unknown:
            return languageManager.t("I can help you analyze your speaking progress. Try asking: \"How is my confidence?\" or \"How much have I practiced today?\"")
        }
    }
    
    // MARK: - Natural Language Processing
    
    enum UserIntent {
        case checkConfidence
        case checkPractice
        case checkHesitation
        case checkWords
        case checkClarity
        case checkSummary
        case greeting
        case unknown
    }
    
    private func analyzeIntent(from text: String) -> UserIntent {
        let tagger = NLTagger(tagSchemes: [.lemma, .nameType])
        tagger.string = text
        
        var foundLemmas: Set<String> = []
        
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .lemma) { tag, tokenRange in
            if let lemma = tag?.rawValue {
                foundLemmas.insert(lemma.lowercased())
            } else {
                // Fallback to original word if lemma fails
                let word = String(text[tokenRange]).lowercased()
                foundLemmas.insert(word)
            }
            return true
        }
        
        // Intelligent Matching based on Lemmas (Root words)
        // e.g. "practicing", "practiced", "practices" -> "practice"
        
        if foundLemmas.contains("confidence") || foundLemmas.contains("confident") {
            return .checkConfidence
        }
        
        if foundLemmas.contains("practice") || foundLemmas.contains("goal") || foundLemmas.contains("minute") || foundLemmas.contains("time") {
            return .checkPractice
        }
        
        if foundLemmas.contains("hesitation") || foundLemmas.contains("hesitate") || foundLemmas.contains("pause") || foundLemmas.contains("um") {
            return .checkHesitation
        }
        
        if foundLemmas.contains("word") || foundLemmas.contains("speak") || foundLemmas.contains("total") {
            return .checkWords
        }
        
        if foundLemmas.contains("clarity") || foundLemmas.contains("clear") || foundLemmas.contains("articulate") {
            return .checkClarity
        }
        
        if foundLemmas.contains("summary") || foundLemmas.contains("stat") || foundLemmas.contains("progress") {
            return .checkSummary
        }
        
        if foundLemmas.contains("hello") || foundLemmas.contains("hi") || foundLemmas.contains("hey") {
            return .greeting
        }
        
        return .unknown
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
                    .background(Color.red)
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
