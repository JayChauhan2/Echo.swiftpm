import SwiftUI

enum AppAppearance: String, CaseIterable, Identifiable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"
    
    var id: String { self.rawValue }
    
    func localizedName(_ languageManager: LanguageManager) -> String {
        return languageManager.t(self.rawValue)
    }
}

class AppearanceManager: ObservableObject {
    static let shared = AppearanceManager()
    
    @AppStorage("selectedAppearance") var currentAppearanceRaw: String = AppAppearance.system.rawValue
    
    var currentAppearance: AppAppearance {
        get {
            return AppAppearance(rawValue: currentAppearanceRaw) ?? .system
        }
        set {
            currentAppearanceRaw = newValue.rawValue
            objectWillChange.send()
        }
    }
    
    var colorScheme: ColorScheme? {
        switch currentAppearance {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}
