import SwiftUI

struct AudioVisualizer: View {
    let amplitude: Float
    
    var body: some View {
        VStack {
            Spacer()
            HStack(spacing: 3) {
                ForEach(0..<60) { i in
                    let x = CGFloat(i - 30)
                    let radius: CGFloat = 38
                    let shapeFactor = max(0, sqrt(pow(radius, 2) - pow(x, 2))) / radius
                    
                    let noise = CGFloat.random(in: 0.5...1.5)
                    let height = CGFloat(amplitude) * 200.0 * shapeFactor * noise
                    
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color.red)
                        .frame(width: 4, height: max(0, height))
                }
            }
            .frame(maxWidth: .infinity, alignment: .bottom)
            .padding(.bottom, 0)
            .offset(y: 20)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .ignoresSafeArea(edges: .bottom)
        .accessibilityHidden(true)
    }
}
