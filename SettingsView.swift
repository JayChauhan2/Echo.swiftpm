import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var languageManager: LanguageManager
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(alignment: .leading, spacing: 20) {
                    
                    Text(languageManager.t("Settings"))
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(.red)
                        .padding(.top)
                        .padding(.horizontal)
                    
                    Form {
                        Section {
                            Picker(languageManager.t("App Language"), selection: $languageManager.currentLanguage) {
                                ForEach(Language.allCases) { language in
                                    Text("\(language.flag) \(language.rawValue)").tag(language)
                                }
                            }
                            .pickerStyle(.navigationLink)
                        } header: {
                            Text(languageManager.t("App Language"))
                                .foregroundStyle(.gray)
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                }
            }
        }
    }
}
