import SwiftUI

struct Theme {
    static let brandPrimary = Color(uiColor: .systemRed)
    static let tint = Color(uiColor: .systemRed)
    
    // Semantic Backgrounds that adapt to Light/Dark mode
    static let background = Color(uiColor: .systemBackground)
    static let secondaryBackground = Color(uiColor: .secondarySystemBackground)
    static let tertiaryBackground = Color(uiColor: .tertiarySystemGroupedBackground) 
    
    // Semantic Labels
    static let primaryLabel = Color(uiColor: .label)
    static let secondaryLabel = Color(uiColor: .secondaryLabel)
    
    // Materials for glass effects (adaptive)
    static let ultraThinMaterial = Material.ultraThin
    static let regularMaterial = Material.regular
}

extension Color {
    // Convenience extensions if needed, but Theme struct is cleaner for now
    static let echoRed = Theme.brandPrimary
}
