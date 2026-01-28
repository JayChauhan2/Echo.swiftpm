import SwiftUI

struct ContentView: View {
    @StateObject var storage = RecordingStorage()
    
    init() {
        // Tab Bar Appearance
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.black
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        TabView {
            // Tab 1: Record
            RecordView(storage: storage)
                .tabItem {
                    Label("Record", systemImage: "mic.fill")
                }
            
            // Tab 2: Progress (Analytics)
            ProgressView(storage: storage)
                .tabItem {
                    Label("Progress", systemImage: "chart.bar.fill")
                }
        }
        .accentColor(.red) // Highlight color
        .preferredColorScheme(.dark)
    }
}
