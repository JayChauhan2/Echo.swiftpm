import SwiftUI

struct AudioVisualizer: View {
    let amplitude: Float
    
    var body: some View {
        Canvas { context, size in
            let barsCount = 60
            let barWidth: CGFloat = 4
            let spacing: CGFloat = 3
            let totalWidth = CGFloat(barsCount) * barWidth + CGFloat(barsCount - 1) * spacing
            let startX = (size.width - totalWidth) / 2
            
            for i in 0..<barsCount {
                let xPos = startX + CGFloat(i) * (barWidth + spacing)
                
                // Shape logic
                let x = CGFloat(i - 30)
                let radius: CGFloat = 38
                // Safety check for sqrt
                let val = (radius * radius) - (x * x)
                let shapeFactor = val > 0 ? sqrt(val) / radius : 0
                
                let noise = CGFloat.random(in: 0.5...1.5)
                let height = CGFloat(amplitude) * 200.0 * shapeFactor * noise
                
                // Draw bar
                let barRect = CGRect(
                    x: xPos,
                    y: size.height - max(0, height) + 20, // Offset y: 20 matching original
                    width: barWidth,
                    height: max(0, height)
                )
                
                context.fill(Path(roundedRect: barRect, cornerRadius: 1), with: .color(.red))
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .accessibilityHidden(true)
    }
}
