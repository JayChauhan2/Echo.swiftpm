import SwiftUI

struct ContentView: View {
    @StateObject var storage = RecordingStorage()
    
    init() {
        // Tab Bar Appearance
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = UIColor.clear
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    @StateObject var effectsState = GlobalEffectsState()
    @StateObject var languageManager = LanguageManager.shared
    @StateObject var appearanceManager = AppearanceManager.shared
    @StateObject var onboardingManager = OnboardingManager()

    var body: some View {
        ZStack {
            // Global Particle Layer - Removed in favor of per-view instances
            // Color.black.ignoresSafeArea()
            // ParticleView(amplitude: effectsState.amplitude, touchLocation: effectsState.touchLocation).ignoresSafeArea()
            
            TabView {
                // Tab 1: Record (Audio)
                RecordView(storage: storage)
                    .tabItem {
                        Label(languageManager.t("Voice"), systemImage: "mic.fill")
                    }
                
                // Tab 2: Camera
                CameraRecordView(storage: storage)
                    .tabItem {
                        Label(languageManager.t("Camera"), systemImage: "video.fill")
                    }
                
                // Tab 3: Library
                LibraryView(storage: storage)
                    .tabItem {
                        Label(languageManager.t("Library"), systemImage: "books.vertical.fill")
                    }
                
                // Tab 4: Progress (Analytics)
                ProgressView(storage: storage)
                    .tabItem {
                        Label(languageManager.t("Progress"), systemImage: "chart.bar.fill")
                    }
                
                // Tab 5: Settings
                SettingsView(storage: storage)
                    .tabItem {
                        Label(languageManager.t("Settings"), systemImage: "ellipsis.circle.fill")
                    }
            }
            .accentColor(Theme.tint) // Highlight color
        }
        .environmentObject(effectsState)
        .environmentObject(languageManager)
        .environmentObject(appearanceManager)
        .environmentObject(onboardingManager)
        .environmentObject(storage)
        .preferredColorScheme(appearanceManager.colorScheme)
        .fullScreenCover(isPresented: $onboardingManager.shouldShowOnboarding) {
            OnboardingView(storage: storage)
                .environmentObject(onboardingManager)
                .environmentObject(storage)
                .environmentObject(languageManager)
        }
        .onAppear {
            // Show onboarding every time the app launches
            onboardingManager.showOnboarding()
        }
    }
}
