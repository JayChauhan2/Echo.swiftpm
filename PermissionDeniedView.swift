import SwiftUI

struct PermissionDeniedView: View {
    let icon: String
    let title: String
    let description: String
    @EnvironmentObject var languageManager: LanguageManager
    
    var body: some View {
        ZStack {
            // Background blur/material
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
            
            VStack(spacing: 20) {
                // Icon with gradient
                ZStack {
                    Circle()
                        .fill(Theme.tint.opacity(0.1))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: icon)
                        .font(.system(size: 40, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Theme.tint, Theme.tint.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .padding(.top, 10)
                
                VStack(spacing: 8) {
                    Text(languageManager.t(title))
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.primaryLabel)
                        .multilineTextAlignment(.center)
                    
                    Text(languageManager.t(description))
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(Theme.secondaryLabel)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .lineSpacing(4)
                }
                
                Button(action: {
                    HapticManager.shared.light()
                    openSettings()
                }) {
                    Text(languageManager.t("Open Settings"))
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Theme.tint)
                        )
                        .padding(.horizontal, 24)
                }
                .padding(.bottom, 10)
            }
            .padding(24)
        }
        .padding(32)
        .transition(.scale.combined(with: .opacity))
    }
    
    private func openSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        
        if UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl)
        }
    }
}

#Preview {
    ZStack {
        Color.gray.ignoresSafeArea()
        PermissionDeniedView(
            icon: "camera.fill",
            title: "Camera access required",
            description: "Allow camera access in settings to start recording your practice sessions."
        )
        .environmentObject(LanguageManager.shared)
    }
}
