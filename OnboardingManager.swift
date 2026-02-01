import Foundation
import SwiftUI

class OnboardingManager: ObservableObject {
    @Published var shouldShowOnboarding: Bool = false
    @Published var isFirstLaunch: Bool = true
    
    private let hasLaunchedBeforeKey = "HasLaunchedBefore"
    
    init() {
        // Check if this is the first launch
        isFirstLaunch = !UserDefaults.standard.bool(forKey: hasLaunchedBeforeKey)
    }
    
    func showOnboarding() {
        shouldShowOnboarding = true
    }
    
    func dismissOnboarding() {
        shouldShowOnboarding = false
        
        // Mark that the app has been launched
        if isFirstLaunch {
            UserDefaults.standard.set(true, forKey: hasLaunchedBeforeKey)
            isFirstLaunch = false
        }
    }
}
