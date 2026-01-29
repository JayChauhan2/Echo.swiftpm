import SwiftUI
import Combine

class GlobalEffectsState: ObservableObject {
    @Published var amplitude: Float = 0.0
    @Published var touchLocation: CGPoint = .zero
}
