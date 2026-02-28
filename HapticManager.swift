import UIKit
import SwiftUI

/// Centralized haptic feedback manager for consistent UX throughout the app
class HapticManager: ObservableObject {
    static let shared = HapticManager()
    
    @Published var isHapticEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isHapticEnabled, forKey: "isHapticEnabled")
        }
    }
    
    private init() {
        // Load initial value from UserDefaults
        self.isHapticEnabled = UserDefaults.standard.object(forKey: "isHapticEnabled") as? Bool ?? true
    }
    
    // MARK: - Haptic Feedback Types
    
    /// Light impact - for subtle interactions like button taps
    func light() {
        guard isHapticEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
    }
    
    /// Medium impact - for standard interactions
    func medium() {
        guard isHapticEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }
    
    /// Heavy impact - for significant actions
    func heavy() {
        guard isHapticEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.prepare()
        generator.impactOccurred()
    }
    
    /// Success notification - for successful completions
    func success() {
        guard isHapticEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
    }
    
    /// Warning notification - for warnings or important alerts
    func warning() {
        guard isHapticEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.warning)
    }
    
    /// Error notification - for errors or failures
    func error() {
        guard isHapticEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.error)
    }
    
    /// Selection changed - for picker/selection changes
    func selection() {
        guard isHapticEnabled else { return }
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }
}
