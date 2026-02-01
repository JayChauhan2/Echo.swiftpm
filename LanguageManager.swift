import SwiftUI
import Combine

enum Language: String, CaseIterable, Identifiable {
    case english = "English"
    case spanish = "Español"
    case french = "Français"
    case japanese = "日本語"
    case german = "Deutsch"
    
    var id: String { self.rawValue }
    
    var flag: String {
        switch self {
        case .english: return "🇺🇸"
        case .spanish: return "🇪🇸"
        case .french: return "🇫🇷"
        case .japanese: return "🇯🇵"
        case .german: return "🇩🇪"
        }
    }
    
    var locale: Locale {
        switch self {
        case .english: return Locale(identifier: "en_US")
        case .spanish: return Locale(identifier: "es_ES")
        case .french: return Locale(identifier: "fr_FR")
        case .japanese: return Locale(identifier: "ja_JP")
        case .german: return Locale(identifier: "de_DE")
        }
    }
}

class LanguageManager: ObservableObject {
    static let shared = LanguageManager()
    
    @AppStorage("selectedLanguage") var currentLanguageRaw: String = Language.english.rawValue
    
    var currentLanguage: Language {
        get {
            return Language(rawValue: currentLanguageRaw) ?? .english
        }
        set {
            currentLanguageRaw = newValue.rawValue
            objectWillChange.send()
        }
    }
    
    var currentLocale: Locale {
        return currentLanguage.locale
    }
    
    func t(_ key: String) -> String {
        if currentLanguage == .english {
            return key
        }
        
        guard let langDict = translations[currentLanguage], let localized = langDict[key] else {
            return key
        }
        
        return localized
    }
    
    // MARK: - Translations
    // Key is always the English string
    private let translations: [Language: [String: String]] = [
        .spanish: [
            "Voice": "Voz",
            "Camera": "Cámara",
            "Library": "Biblioteca",
            "Progress": "Progreso",
            "Settings": "Ajustes",
            
            // RecordView
            "Recording...": "Grabando...",
            "Tap to record": "Toca para grabar",
            "Analyzing Audio...": "Analizando Audio...",
            
            // CameraRecordView
            "Camera access required": "Acceso a la cámara requerido",
            "Open Settings": "Abrir Ajustes",
            "Recording Presence...": "Grabando Presencia...",
            "Analyzing Presence...": "Analizando Presencia...",
            
            // LibraryView
            "Your library is empty": "Tu biblioteca está vacía",
            "Recordings you save will appear here": "Las grabaciones que guardes aparecerán aquí",
            "Delete": "Eliminar",
            "Delete Recording": "Eliminar Grabación",
            "Cancel": "Cancelar",
            
            // ProgressView
            "Your Progress 🚀": "Tu Progreso 🚀",
            "Practice, reflection, and growth over time": "Práctica, reflexión y crecimiento con el tiempo",
            "Daily Goal": "Meta Diaria",
            "min today": "min hoy",
            "Confidence": "Confianza",
            "this week": "esta semana",
            "consistent": "consistente",
            "Confidence Over Time": "Confianza a lo largo del tiempo",
            "Start recording to see your growth": "Empieza a grabar para ver tu crecimiento",
            "Clarity": "Claridad",
            "Crystal clear": "Cristalino",
            "Good effort": "Buen esfuerzo",
            "Hesitation": "Duda",
            "Flow state": "Estado de flujo",
            "Words practiced total": "Palabras practicadas en total", // New key
            
            // App settings
            "App Language": "Idioma de la Aplicación",
            "Appearance": "Apariencia",
            "System": "Sistema",
            "Light": "Claro",
            "Dark": "Oscuro",
            
            // Motivational Messages
             "Ready to Rock Today?": "¿Listo para rockear hoy?",
             "Time to shine!": "¡Es hora de brillar!",
             "Capture your brilliant thoughts!": "¡Captura tus pensamientos brillantes!",
             "Let's make some magic!": "¡Hagamos magia!",
             "Your voice matters!": "¡Tu voz importa!",
             "Speak your mind!": "¡Di lo que piensas!",
             "Go for it!": "¡Ve a por ello!",
             "Unleash your creativity!": "¡Desata tu creatividad!",
             "Today is a great day!": "¡Hoy es un gran día!",
             "Record your genius!": "¡Graba tu genialidad!",
             "Smile for the camera!": "¡Sonríe a la cámara!",
             "Show your confidence!": "¡Muestra tu confianza!",
             "Eyes on the prize!": "¡Ojos en el premio!",
             "You look great!": "¡Te ves genial!",
             "Stand tall!": "¡Mantente erguido!",
             "Ready for your closeup?": "¿Listo para tu primer plano?",
             "Project your presence!": "¡Proyecta tu presencia!",
             "Share your vision!": "¡Comparte tu visión!",
             "Be yourself!": "¡Sé tú mismo!",
             "Lights, Camera, Action!": "¡Luces, Cámara, Acción!",
             
             // AI Assistant
             "Echo Assistant": "Asistente Echo",
             "Hello! I'm your Echo Assistant. I can analyze your speaking data. Ask me about your confidence, practice usage, or hesitation trends!": "¡Hola! Soy tu Asistente Echo. Puedo analizar tus datos de habla. ¡Pregúntame sobre tu confianza, uso de práctica o tendencias de vacilación!",
             "Ask about your progress...": "Pregunta sobre tu progreso...",
             "Done": "Hecho",
             "Your current confidence score is": "Tu puntuación de confianza actual es",
             "You are": "Estás",
             "improving by": "mejorando por",
             "down by": "bajando por",
             "steady": "estable",
             "Keep practicing to boost your projection!": "¡Sigue practicando para mejorar tu proyección!",
             "You've practiced for": "Has practicado por",
             "minutes today against your goal of": "minutos hoy contra tu meta de",
             "minutes. Every minute counts!": "minutos. ¡Cada minuto cuenta!",
             "Regarding hesitations:": "Con respecto a las dudas:",
             "Reducing pauses helps with flow state.": "Reducir las pausas ayuda con el estado de flujo.",
             "You have spoken a total of": "Has hablado un total de",
             "words across all your sessions. That's a lot of practice!": "palabras en todas tus sesiones. ¡Es mucha práctica!",
             "Your clarity score is currently": "Tu puntuación de claridad es actualmente",
             "You're speaking very clearly!": "¡Estás hablando muy claramente!",
             "Try to articulate more precisely.": "Intenta articular con más precisión.",
             "Here is your summary:": "Aquí está tu resumen:",
             "Today's Practice:": "Práctica de hoy:",
             "Hesitation:": "Duda:",
             "You're doing great!": "¡Lo estás haciendo genial!",
             "I can help you analyze your speaking progress. Try asking: \"How is my confidence?\" or \"How much have I practiced today?\"": "Puedo ayudarte a analizar tu progreso al hablar. Intenta preguntar: \"¿Cómo está mi confianza?\" o \"¿Cuánto he practicado hoy?\"",
             
             // ProgressViewModel
             "Stable": "Estable",
             "Very few pauses": "Muy pocas pausas",
             "Normal flow": "Flujo normal",
             "High pauses": "Muchas pausas",
             "No analysis yet": "Sin análisis aún",
             "No data this week": "Sin datos esta semana",
             "Analyzing...": "Analizando...",
             
             // Onboarding
             "Welcome to Echo": "Bienvenido a Echo",
             "Welcome Back": "Bienvenido de Nuevo",
             "Welcome to Echo! This app helps you improve your communication skills through voice and video analysis. Practice regularly, track your progress, and watch your confidence grow.": "¡Bienvenido a Echo! Esta aplicación te ayuda a mejorar tus habilidades de comunicación a través del análisis de voz y video. Practica regularmente, rastrea tu progreso y observa cómo crece tu confianza.",
             "Ready to start your journey? Record your first practice session and discover insights about your communication style.": "¿Listo para comenzar tu viaje? Graba tu primera sesión de práctica y descubre información sobre tu estilo de comunicación.",
             "Keep going! Consistency is key. Try focusing on speaking slowly and clearly in your next session.": "¡Sigue adelante! La consistencia es clave. Intenta enfocarte en hablar lenta y claramente en tu próxima sesión.",
             "Excellent work! Your confidence is improving. Consider increasing your practice goal to challenge yourself further.": "¡Excelente trabajo! Tu confianza está mejorando. Considera aumentar tu meta de práctica para desafiarte más.",
             "You're doing great! Your confidence is strong and you've hit your daily goal. Keep up the amazing work!": "¡Lo estás haciendo genial! Tu confianza es fuerte y has alcanzado tu meta diaria. ¡Sigue con el trabajo increíble!",
             "Welcome back! Ready to continue improving your communication skills? Let's make today count.": "¡Bienvenido de nuevo! ¿Listo para seguir mejorando tus habilidades de comunicación? Hagamos que hoy cuente.",
             "I'm Ready!": "¡Estoy Listo!",
             "I'm Ready! Dismiss onboarding": "¡Estoy Listo! Descartar incorporación",
             "Double tap to start using Echo": "Toca dos veces para comenzar a usar Echo",
             "Voice Recording": "Grabación de Voz",
             "Record and analyze your voice for clarity and confidence": "Graba y analiza tu voz para claridad y confianza",
             "Video Analysis": "Análisis de Video",
             "Capture your presence and body language": "Captura tu presencia y lenguaje corporal",
             "Track Progress": "Rastrear Progreso",
             "Monitor your improvement over time": "Monitorea tu mejora con el tiempo",
             "AI Insights": "Perspectivas de IA",
             "Get personalized feedback and suggestions": "Obtén retroalimentación y sugerencias personalizadas",
             
             // Returning User Onboarding
             "Level Up Your Voice": "Mejora Tu Voz",
             "Continue practicing to unlock your full vocal potential": "Continúa practicando para desbloquear todo tu potencial vocal",
             "Smart Analysis": "Análisis Inteligente",
             "Did you know Echo spots filler words like 'um' and 'ah' to help you sound pro?": "¿Sabías que Echo detecta muletillas como 'eh' y 'em' para ayudarte a sonar profesional?",
             "Measure Your Impact": "Mide Tu Impacto",
             "See exactly how confident you appear with advanced AI analysis": "Mira exactamente cuán seguro pareces con el análisis avanzado de IA"
        ],
        .french: [
            "Voice": "Voix",
            "Camera": "Caméra",
            "Library": "Bibliothèque",
            "Progress": "Progrès",
            "Settings": "Paramètres",
            
            "Recording...": "Enregistrement...",
            "Tap to record": "Appuyez pour enregistrer",
            "Analyzing Audio...": "Analyse audio...",
            
            "Camera access required": "Accès caméra requis",
            "Open Settings": "Ouvrir les paramètres",
            "Recording Presence...": "Enregistrement présence...",
            "Analyzing Presence...": "Analyse présence...",
            
            "Your library is empty": "Votre bibliothèque est vide",
            "Recordings you save will appear here": "Vos enregistrements apparaîtront ici",
            "Delete": "Supprimer",
            "Delete Recording": "Supprimer l'enregistrement",
            "Cancel": "Annuler",
            
            "Your Progress 🚀": "Votre Progrès 🚀",
            "Practice, reflection, and growth over time": "Pratique, réflexion et croissance au fil du temps",
            "Daily Goal": "Objectif quotidien",
            "min today": "min aujourd'hui",
            "Confidence": "Confiance",
            "this week": "cette semaine",
            "consistent": "cohérent",
            "Confidence Over Time": "Confiance au fil du temps",
            "Start recording to see your growth": "Commencez à enregistrer pour voir votre croissance",
            "Clarity": "Clarté",
            "Crystal clear": "Cristallin",
            "Good effort": "Bon effort",
            "Hesitation": "Hésitation",
            "Flow state": "État de flux",
            "Words practiced total": "Mots pratiqués au total",
            
            "App Language": "Langue de l'application",
            "Appearance": "Apparence",
            "System": "Système",
            "Light": "Clair",
            "Dark": "Sombre",
            
            "Ready to Rock Today?": "Prêt pour aujourd'hui?",
            "Time to shine!": "C'est l'heure de briller!",
            "Capture your brilliant thoughts!": "Capturez vos pensées brillantes!",
            "Let's make some magic!": "Faisons de la magie!",
            "Your voice matters!": "Votre voix compte!",
            "Speak your mind!": "Exprimez-vous!",
            "Go for it!": "Allez-y!",
            "Unleash your creativity!": "Libérez votre créativité!",
            "Today is a great day!": "Aujourd'hui est un grand jour!",
            "Record your genius!": "Enregistrez votre génie!",
            "Smile for the camera!": "Souriez pour la caméra!",
            "Show your confidence!": "Montrez votre confiance!",
            "Eyes on the prize!": "Yeux sur le prix!",
            "You look great!": "Vous avez l'air génial!",
            "Stand tall!": "Tenez-vous droit!",
            "Ready for your closeup?": "Prêt pour votre gros plan?",
            "Project your presence!": "Projetez votre présence!",
            "Share your vision!": "Partagez votre vision!",
            "Be yourself!": "Soyez vous-même!",
            "Lights, Camera, Action!": "Lumières, Caméra, Action!",
            
            // AI Assistant
            "Echo Assistant": "Assistant Echo",
            "Hello! I'm your Echo Assistant. I can analyze your speaking data. Ask me about your confidence, practice usage, or hesitation trends!": "Bonjour ! Je suis votre Assistant Echo. Je peux analyser vos données de parole. Interrogez-moi sur votre confiance, votre pratique ou vos tendances d'hésitation !",
            "Ask about your progress...": "Demandez sur vos progrès...",
            "Done": "Fait",
            "Your current confidence score is": "Votre score de confiance actuel est",
            "You are": "Vous êtes",
            "improving by": "en amélioration de",
            "down by": "en baisse de",
            "steady": "stable",
            "Keep practicing to boost your projection!": "Continuez à pratiquer pour améliorer votre projection !",
            "You've practiced for": "Vous avez pratiqué pendant",
            "minutes today against your goal of": "minutes aujourd'hui contre votre objectif de",
            "minutes. Every minute counts!": "minutes. Chaque minute compte !",
            "Regarding hesitations:": "Concernant les hésitations :",
            "Reducing pauses helps with flow state.": "Réduire les pauses aide à l'état de flux.",
            "You have spoken a total of": "Vous avez parlé un total de",
            "words across all your sessions. That's a lot of practice!": "mots dans toutes vos sessions. C'est beaucoup de pratique !",
            "Your clarity score is currently": "Votre score de clarté est actuellement",
            "You're speaking very clearly!": "Vous parlez très clairement !",
            "Try to articulate more precisely.": "Essayez d'articuler plus précisément.",
            "Here is your summary:": "Voici votre résumé :",
            "Today's Practice:": "Pratique d'aujourd'hui :",
            "Hesitation:": "Hésitation :",
            "You're doing great!": "Vous vous débrouillez très bien !",
            "I can help you analyze your speaking progress. Try asking: \"How is my confidence?\" or \"How much have I practiced today?\"": "Je peux vous aider à analyser vos progrès. Essayez de demander : \"Comment est ma confiance ?\" ou \"Combien ai-je pratiqué aujourd'hui ?\"",
            
            // ProgressViewModel
            "Stable": "Stable",
            "Very few pauses": "Très peu de pauses",
            "Normal flow": "Flux normal",
            "High pauses": "Beaucoup de pauses",
            "No analysis yet": "Pas encore d'analyse",
            "No data this week": "Pas de données cette semaine",
            "Analyzing...": "Analyse en cours..."
        ],
        .japanese: [
            "Voice": "音声",
            "Camera": "カメラ",
            "Library": "ライブラリ",
            "Progress": "進捗",
            "Settings": "設定",
            
            "Recording...": "録音中...",
            "Tap to record": "タップして録音",
            "Analyzing Audio...": "音声分析中...",
            
            "Camera access required": "カメラへのアクセスが必要です",
            "Open Settings": "設定を開く",
            "Recording Presence...": "プレゼンスを記録中...",
            "Analyzing Presence...": "プレゼンス分析中...",
            
            "Your library is empty": "ライブラリは空です",
            "Recordings you save will appear here": "保存した録画はここに表示されます",
            "Delete": "削除",
            "Delete Recording": "録画を削除",
            "Cancel": "キャンセル",
            
            "Your Progress 🚀": "あなたの進捗 🚀",
            "Practice, reflection, and growth over time": "練習、振り返り、そして成長",
            "Daily Goal": "毎日の目標",
            "min today": "今日の分",
            "Confidence": "自信",
            "this week": "今週",
            "consistent": "安定",
            "Confidence Over Time": "自信の推移",
            "Start recording to see your growth": "成長を見るために録画を開始",
            "Clarity": "明瞭さ",
            "Crystal clear": "非常に明確",
            "Good effort": "良い努力",
            "Hesitation": "躊躇",
            "Flow state": "フロー状態",
            "Words practiced total": "練習した単語の合計",
            
            "App Language": "アプリの言語",
            "Appearance": "外観",
            "System": "システム",
            "Light": "ライト",
            "Dark": "ダーク",
            
            "Ready to Rock Today?": "今日も頑張る準備はいい？",
            "Time to shine!": "輝く時間です！",
            "Capture your brilliant thoughts!": "素晴らしい考えを記録しよう！",
            "Let's make some magic!": "魔法を起こそう！",
            "Your voice matters!": "あなたの声は重要です！",
            "Speak your mind!": "思いを伝えよう！",
            "Go for it!": "やってみよう！",
            "Unleash your creativity!": "創造性を解き放て！",
            "Today is a great day!": "今日は素晴らしい日です！",
            "Record your genius!": "天才を記録しよう！",
            "Smile for the camera!": "カメラに向かって笑顔！",
            "Show your confidence!": "自信を見せよう！",
            "Eyes on the prize!": "目標を見据えて！",
            "You look great!": "素敵ですよ！",
            "Stand tall!": "胸を張って！",
            "Ready for your closeup?": "クローズアップの準備は？",
            "Project your presence!": "存在感を放て！",
            "Share your vision!": "ビジョンを共有しよう！",
            "Be yourself!": "あなたらしく！",
            "Lights, Camera, Action!": "ライト、カメラ、アクション！",
            
            // AI Assistant
            "Echo Assistant": "Echo アシスタント",
            "Hello! I'm your Echo Assistant. I can analyze your speaking data. Ask me about your confidence, practice usage, or hesitation trends!": "こんにちは！私はEchoアシスタントです。あなたの話し方のデータを分析できます。自信、練習量、または躊躇の傾向について聞いてください！",
            "Ask about your progress...": "進捗について聞く...",
            "Done": "完了",
            "Your current confidence score is": "現在の自信スコアは",
            "You are": "あなたは",
            "improving by": "改善しています：",
            "down by": "低下しています：",
            "steady": "安定しています",
            "Keep practicing to boost your projection!": "練習を続けて、発声を強化しましょう！",
            "You've practiced for": "今日の練習時間は",
            "minutes today against your goal of": "分です。目標は",
            "minutes. Every minute counts!": "分です。毎分が大切です！",
            "Regarding hesitations:": "躊躇に関しては：",
            "Reducing pauses helps with flow state.": "ポーズを減らすとフローステートに入りやすくなります。",
            "You have spoken a total of": "これまでに話した合計単語数は",
            "words across all your sessions. That's a lot of practice!": "語です。素晴らしい練習量です！",
            "Your clarity score is currently": "現在の明瞭さスコアは",
            "You're speaking very clearly!": "とてもはっきりと話せています！",
            "Try to articulate more precisely.": "もっと正確に発音してみましょう。",
            "Here is your summary:": "これがあなたのまとめです：",
            "Today's Practice:": "今日の練習：",
            "Hesitation:": "躊躇：",
            "You're doing great!": "よく頑張っています！",
            "I can help you analyze your speaking progress. Try asking: \"How is my confidence?\" or \"How much have I practiced today?\"": "進捗の分析をお手伝いします。「自信はどう？」や「今日はどれくらい練習した？」と聞いてみてください。",
            
            // ProgressViewModel
            "Stable": "安定",
            "Very few pauses": "ほとんどポーズなし",
            "Normal flow": "通常のフロー",
            "High pauses": "ポーズが多い",
            "No analysis yet": "分析なし",
            "No data this week": "今週のデータなし",
            "Analyzing...": "分析中..."
        ],
        .german: [
            "Voice": "Stimme",
            "Camera": "Kamera",
            "Library": "Bibliothek",
            "Progress": "Fortschritt",
            "Settings": "Einstellungen",
            
            "Recording...": "Aufnahme...",
            "Tap to record": "Zum Aufnehmen tippen",
            "Analyzing Audio...": "Audio analysieren...",
            
            "Camera access required": "Kamerazugriff erforderlich",
            "Open Settings": "Einstellungen öffnen",
            "Recording Presence...": "Präsenz aufnehmen...",
            "Analyzing Presence...": "Präsenz analysieren...",
            
            "Your library is empty": "Deine Bibliothek ist leer",
            "Recordings you save will appear here": "Gespeicherte Aufnahmen erscheinen hier",
            "Delete": "Löschen",
            "Delete Recording": "Aufnahme löschen",
            "Cancel": "Abbrechen",
            
            "Your Progress 🚀": "Dein Fortschritt 🚀",
            "Practice, reflection, and growth over time": "Übung, Reflexion und Wachstum im Laufe der Zeit",
            "Daily Goal": "Tagesziel",
            "min today": "Min heite",
            "Confidence": "Selbstvertrauen",
            "this week": "diese Woche",
            "consistent": "konsistent",
            "Confidence Over Time": "Selbstvertrauen im Zeitverlauf",
            "Start recording to see your growth": "Beginne aufzunehmen, um dein Wachstum zu sehen",
            "Clarity": "Klarheit",
            "Crystal clear": "Kristallklar",
            "Good effort": "Guter Versuch",
            "Hesitation": "Zögern",
            "Flow state": "Flow-Zustand",
            "Words practiced total": "Geübte Wörter insgesamt",
            
            "App Language": "App-Sprache",
            "Appearance": "Erscheinungsbild",
            "System": "System",
            "Light": "Hell",
            "Dark": "Dunkel",
            
             "Ready to Rock Today?": "Bereit loszulegen?",
             "Time to shine!": "Zeit zu glänzen!",
             "Capture your brilliant thoughts!": "Halte deine genialen Gedanken fest!",
             "Let's make some magic!": "Lass uns Magie machen!",
             "Your voice matters!": "Deine Stimme zählt!",
             "Speak your mind!": "Sag deine Meinung!",
             "Go for it!": "Mach es einfach!",
             "Unleash your creativity!": "Entfessle deine Kreativität!",
             "Today is a great day!": "Heute ist ein toller Tag!",
             "Record your genius!": "Nimm dein Genie auf!",
             "Smile for the camera!": "Lächle für die Kamera!",
             "Show your confidence!": "Zeig dein Selbstvertrauen!",
             "Eyes on the prize!": "Das Ziel im Blick!",
             "You look great!": "Du siehst toll aus!",
             "Stand tall!": "Kopf hoch!",
             "Ready for your closeup?": "Bereit für deine Nahaufnahme?",
             "Project your presence!": "Projeziere deine Präsenz!",
             "Share your vision!": "Teile deine Vision!",
             "Be yourself!": "Sei du selbst!",
             "Lights, Camera, Action!": "Licht, Kamera, Action!",
             
             // AI Assistant
             "Echo Assistant": "Echo Assistent",
             "Hello! I'm your Echo Assistant. I can analyze your speaking data. Ask me about your confidence, practice usage, or hesitation trends!": "Hallo! Ich bin dein Echo Assistent. Ich kann deine Sprachdaten analysieren. Frag mich nach deinem Selbstvertrauen, deiner Übung oder deinen Zögertrends!",
             "Ask about your progress...": "Frag nach deinem Fortschritt...",
             "Done": "Fertig",
             "Your current confidence score is": "Dein aktueller Selbstvertrauenswert ist",
             "You are": "Du bist",
             "improving by": "verbessert um",
             "down by": "gesunken um",
             "steady": "stabil",
             "Keep practicing to boost your projection!": "Übe weiter, um deine Projektion zu steigern!",
             "You've practiced for": "Du hast heute geübt für",
             "minutes today against your goal of": "Minuten gegen dein Ziel von",
             "minutes. Every minute counts!": "Minuten. Jede Minute zählt!",
             "Regarding hesitations:": "Bezüglich Zögern:",
             "Reducing pauses helps with flow state.": "Pausen zu reduzieren hilft beim Flow-Zustand.",
             "You have spoken a total of": "Du hast insgesamt gesprochen",
             "words across all your sessions. That's a lot of practice!": "Wörter in allen Sitzungen. Das ist viel Übung!",
             "Your clarity score is currently": "Dein Klarheitswert ist aktuell",
             "You're speaking very clearly!": "Du sprichst sehr deutlich!",
             "Try to articulate more precisely.": "Versuche präziser zu artikulieren.",
             "Here is your summary:": "Hier ist deine Zusammenfassung:",
             "Today's Practice:": "Heutige Übung:",
             "Hesitation:": "Zögern:",
             "You're doing great!": "Du machst das toll!",
             "I can help you analyze your speaking progress. Try asking: \"How is my confidence?\" or \"How much have I practiced today?\"": "Ich kann helfen, deinen Sprachfortschritt zu analysieren. Versuch zu fragen: \"Wie ist mein Selbstvertrauen?\" oder \"Wie viel habe ich heute geübt?\"",
            
            // ProgressViewModel
            "Stable": "Stabil",
            "Very few pauses": "Sehr wenige Pausen",
            "Normal flow": "Normaler Fluss",
            "High pauses": "Viele Pausen",
            "No analysis yet": "Noch keine Analyse",
            "No data this week": "Keine Daten diese Woche",
            "Analyzing...": "Analysieren..."
        ]
    ]
}
// Temporary marker for onboarding translations
