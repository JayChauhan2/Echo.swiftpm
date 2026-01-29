import SwiftUI
import CoreMotion

class GlobalEffectsState: ObservableObject {
    @Published var amplitude: Float = 0.0
    @Published var touchLocation: CGPoint = .zero
    @Published var gravity: CGPoint = .zero
    
    private let motionManager = CMMotionManager()
    
    init() {
        startMotionUpdates()
    }
    
    private func startMotionUpdates() {
        guard motionManager.isDeviceMotionAvailable else { return }
        
        motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
            guard let self = self, let motion = motion else { return }
            
            // Map gravity to screen coordinates
            // Gravity Z is into the screen when holding flat.
            // Gravity X is roughly left/right tilt.
            // Gravity Y is roughly up/down tilt.
            // We'll scale it slightly to make it impactful but not overwhelming.
            
            withAnimation(.linear(duration: 0.1)) {
                self.gravity = CGPoint(x: CGFloat(motion.gravity.x), y: CGFloat(-motion.gravity.y))
            }
        }
    }
}
