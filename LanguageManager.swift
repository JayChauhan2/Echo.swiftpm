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
             "Lights, Camera, Action!": "¡Luces, Cámara, Acción!"
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
            "Lights, Camera, Action!": "Lumières, Caméra, Action!"
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
            "Lights, Camera, Action!": "ライト、カメラ、アクション！"
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
             "Lights, Camera, Action!": "Licht, Kamera, Action!"
        ]
    ]
}
