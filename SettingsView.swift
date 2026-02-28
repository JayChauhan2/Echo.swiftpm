import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var languageManager: LanguageManager
    @EnvironmentObject var appearanceManager: AppearanceManager
    @EnvironmentObject var storage: RecordingStorage
    @StateObject private var progressViewModel: ProgressViewModel
    @ObservedObject var hapticManager = HapticManager.shared
    @State private var showDeleteConfirmation = false
    
    init(storage: RecordingStorage) {
        _progressViewModel = StateObject(wrappedValue: ProgressViewModel(storage: storage))
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Stepper(value: $progressViewModel.practiceGoalMinutes, in: 5...60, step: 5) {
                        HStack {
                            Text(languageManager.t("Daily Practice Goal"))
                            Spacer()
                            Text("\(progressViewModel.practiceGoalMinutes) \(languageManager.t("minutes"))")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Picker(languageManager.t("Appearance"), selection: $appearanceManager.currentAppearance) {
                        ForEach(AppAppearance.allCases) { appearance in
                            Text(appearance.localizedName(languageManager)).tag(appearance)
                        }
                    }
                    
                    Toggle(languageManager.t("Haptic Feedback"), isOn: $hapticManager.isHapticEnabled)
                        .tint(Theme.tint)
                } header: {
                    Text(languageManager.t("Personalization"))
                }
                
                Section {
                    HStack {
                        Text(languageManager.t("Version"))
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text(languageManager.t("About"))
                }
                
                Section {
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                            Text(languageManager.t("Clear All History"))
                        }
                    }
                } header: {
                    Text(languageManager.t("Privacy"))
                }
            }
            .navigationTitle(languageManager.t("Settings"))
            .scrollContentBackground(.hidden)
            .background(Theme.background)
            .alert(languageManager.t("Clear All History"), isPresented: $showDeleteConfirmation) {
                Button(languageManager.t("Cancel"), role: .cancel) { }
                Button(languageManager.t("Delete"), role: .destructive) {
                    storage.clearAll()
                    progressViewModel.recalculateMetrics()
                    HapticManager.shared.error()
                }
            } message: {
                Text(languageManager.t("This will permanently delete all your recordings and reset your progress."))
            }
        }
    }
}
