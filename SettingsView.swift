import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var languageManager: LanguageManager
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker(languageManager.t("App Language"), selection: $languageManager.currentLanguage) {
                        ForEach(Language.allCases) { language in
                            Text("\(language.flag) \(language.rawValue)").tag(language)
                        }
                    }
                    .pickerStyle(.menu)
                } header: {
                    Text(languageManager.t("App Language"))
                }
            }
            .navigationTitle(languageManager.t("Settings"))
            .scrollContentBackground(.hidden)
            .background(Theme.background)
        }
    }
}
