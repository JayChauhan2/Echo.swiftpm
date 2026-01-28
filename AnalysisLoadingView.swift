import SwiftUI

struct AnalysisLoadingView: View {
    @State private var phase: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Multiple rings expanding out to imitate "infinity"
            ForEach(0..<6) { i in
                loadingRing(index: i)
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                phase = 3.0 // Move outward significantly
            }
        }
    }
    
    private func loadingRing(index: Int) -> some View {
        let i = CGFloat(index)
        let scale = 1.0 + i + phase
        let opacity = 1.0 - (phase / 3.0)
        
        // Ensure opacity is valid
        let safeOpacity = max(0.0, min(1.0, opacity))
        
        let rotation = Double(i) * 30.0 + Double(phase) * 10.0
        
        return Circle()
            .stroke(lineWidth: 4)
            .foregroundStyle(
                LinearGradient(
                    colors: [.red.opacity(0), .red, .red.opacity(0)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: 50, height: 50)
            .scaleEffect(scale)
            .opacity(safeOpacity)
            .rotationEffect(.degrees(rotation))
    }
}
