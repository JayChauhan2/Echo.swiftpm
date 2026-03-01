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

    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @State private var selectedTab: Tab? = .voice
    @State private var isSplashScreenActive = true

    enum Tab: String, CaseIterable, Identifiable {
        case voice, camera, library, progress, settings
        var id: String { self.rawValue }
        
        var label: String {
            switch self {
            case .voice: return "Voice"
            case .camera: return "Camera"
            case .library: return "Library"
            case .progress: return "Progress"
            case .settings: return "Settings"
            }
        }
        
        var icon: String {
            switch self {
            case .voice: return "mic.fill"
            case .camera: return "video.fill"
            case .library: return "books.vertical.fill"
            case .progress: return "chart.bar.fill"
            case .settings: return "ellipsis.circle.fill"
            }
        }
    }

    var body: some View {
        ZStack {
            Group {
                if horizontalSizeClass == .regular {
                    NavigationSplitView {
                        List(selection: $selectedTab) {
                            ForEach(Tab.allCases) { tab in
                                NavigationLink(value: tab) {
                                    Label(languageManager.t(tab.label), systemImage: tab.icon)
                                }
                            }
                        }
                        .navigationTitle("Echo")
                    } detail: {
                        detailView(for: selectedTab ?? .voice)
                    }
                } else {
                    TabView(selection: Binding(
                        get: { selectedTab ?? .voice },
                        set: { selectedTab = $0 }
                    )) {
                        ForEach(Tab.allCases) { tab in
                            detailView(for: tab)
                                .tabItem {
                                    Label(languageManager.t(tab.label), systemImage: tab.icon)
                                }
                                .tag(tab)
                        }
                    }
                    .accentColor(Theme.brandPrimary)
                }
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
                onboardingManager.showOnboarding()
            }
            .opacity(isSplashScreenActive ? 0 : 1)
            
            if isSplashScreenActive {
                LaunchScreenView()
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                withAnimation(.easeInOut(duration: 0.6)) {
                    isSplashScreenActive = false
                }
            }
        }
    }

    @ViewBuilder
    private func detailView(for tab: Tab) -> some View {
        switch tab {
        case .voice:
            RecordView(storage: storage)
        case .camera:
            CameraRecordView(storage: storage)
        case .library:
            LibraryView(storage: storage)
        case .progress:
            ProgressView(storage: storage)
        case .settings:
            SettingsView(storage: storage)
        }
    }
}
