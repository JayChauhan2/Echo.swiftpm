import SwiftUI

struct LaunchScreenView: View {
    @State private var pulseAmount: CGFloat = 1.0
    @State private var secondPulseAmount: CGFloat = 1.0
    @State private var opacity: Double = 0.0
    
    var body: some View {
        ZStack {
            Theme.background
                .ignoresSafeArea()
            
            // Animated background pulses
            Circle()
                .stroke(Theme.brandPrimary.opacity(0.3), lineWidth: 2)
                .frame(width: 100 * pulseAmount, height: 100 * pulseAmount)
                .opacity(Double(2.0 - pulseAmount))
            
            Circle()
                .stroke(Theme.brandPrimary.opacity(0.2), lineWidth: 1)
                .frame(width: 100 * secondPulseAmount, height: 100 * secondPulseAmount)
                .opacity(Double(2.0 - secondPulseAmount))
            
            VStack(spacing: 24) {
                // Central Logo / Icon
                ZStack {
                    Circle()
                        .fill(Theme.brandPrimary)
                        .frame(width: 80, height: 80)
                        .shadow(color: Theme.brandPrimary.opacity(0.5), radius: 10, x: 0, y: 5)
                    
                    Image(systemName: "mic.fill")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)
                }
                .scaleEffect(opacity) // Simple entrance animation
                
                VStack(spacing: 8) {
                    Text("Echo")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.primaryLabel)
                        .tracking(1.5)
                    
                    Text("Capture your voice.")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(Theme.secondaryLabel)
                        .opacity(0.8)
                }
                .offset(y: (1.0 - opacity) * 20)
                .opacity(opacity)
            }
        }
        .onAppear {
            // Logo entrance
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7, blendDuration: 0).delay(0.2)) {
                opacity = 1.0
            }
            
            // Continuous pulses
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: false)) {
                pulseAmount = 2.0
            }
            
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: false).delay(1.0)) {
                secondPulseAmount = 2.0
            }
        }
    }
}

#Preview {
    LaunchScreenView()
}
