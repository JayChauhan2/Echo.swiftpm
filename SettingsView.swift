import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var languageManager: LanguageManager
    @EnvironmentObject var appearanceManager: AppearanceManager
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker(languageManager.t("Appearance"), selection: $appearanceManager.currentAppearance) {
                        ForEach(AppAppearance.allCases) { appearance in
                            Text(appearance.localizedName(languageManager)).tag(appearance)
                        }
                    }
                    .pickerStyle(.menu)
                } header: {
                    Text(languageManager.t("Appearance"))
                }
                
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
