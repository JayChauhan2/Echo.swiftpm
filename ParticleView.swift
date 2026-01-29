import SwiftUI

struct Particle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat
    var opacity: Double
    var velocityX: CGFloat
    var velocityY: CGFloat
    var baseVelocityX: CGFloat
    var baseVelocityY: CGFloat
    var color: Color
    var blur: CGFloat
}

struct ParticleView: View {
    var amplitude: Float = 0.0
    var touchLocation: CGPoint = .zero // Add touch location property
    
    @State private var particles: [Particle] = []
    
    // "Vibey" colors: Hot Pink, Electric Purple, Bright Orange, Cyan
    private let colors: [Color] = [
        Color(red: 1.0, green: 0.0, blue: 0.5), // Hot Pink
        Color(red: 0.6, green: 0.0, blue: 1.0), // Electric Purple
        Color(red: 1.0, green: 0.4, blue: 0.0), // Bright Orange
        Color(red: 0.0, green: 1.0, blue: 1.0)  // Cyan
    ]
    
    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                // Additive blending for that "glowing" energy look
                context.blendMode = .plusLighter
                
                for particle in particles {
                    var contextCopy = context
                    contextCopy.opacity = particle.opacity
                    contextCopy.addFilter(.blur(radius: particle.blur))
                    
                    let rect = CGRect(
                        x: particle.x,
                        y: particle.y,
                        width: particle.size,
                        height: particle.size
                    )
                    
                    contextCopy.fill(Path(ellipseIn: rect), with: .color(particle.color))
                }
            }
            .onAppear {
                initializeParticles()
            }
            .onChange(of: timeline.date) { _ in
                updateParticles()
            }
        }
    }
    
    private func initializeParticles() {
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        
        // Increased count for more energy
        particles = (0..<80).map { _ in
            createRandomParticle(screenWidth: screenWidth, screenHeight: screenHeight)
        }
    }
    
    private func createRandomParticle(screenWidth: CGFloat, screenHeight: CGFloat) -> Particle {
        let vx = CGFloat.random(in: -0.5...0.5)
        let vy = CGFloat.random(in: -0.5...0.5)
        
        return Particle(
            x: CGFloat.random(in: 0...screenWidth),
            y: CGFloat.random(in: 0...screenHeight),
            size: CGFloat.random(in: 10...30), // Reverted to smaller size
            opacity: Double.random(in: 0.4...0.8),
            velocityX: vx,
            velocityY: vy,
            baseVelocityX: vx,
            baseVelocityY: vy,
            color: colors.randomElement()!,
            blur: CGFloat.random(in: 2...8) // Variable blur for depth
        )
    }
    
    private func updateParticles() {
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        
        // Amplitude factor to energize particles
        let energyFactor = CGFloat(1.0 + (amplitude * 5.0))
        
        for i in particles.indices {
            // physics parameters
            let damping: CGFloat = 0.95 // How fast it slows down (0.9 to 0.99)
            let returnStrength: CGFloat = 0.02 // How fast it returns to base velocity
            
            // Interaction with touch
            if touchLocation != .zero {
                let particleCenter = CGPoint(x: particles[i].x + particles[i].size / 2, y: particles[i].y + particles[i].size / 2)
                let distanceX = particleCenter.x - touchLocation.x
                let distanceY = particleCenter.y - touchLocation.y
                let distance = sqrt(distanceX * distanceX + distanceY * distanceY)
                
                let interactionRadius: CGFloat = 200.0 // Larger radius for "fly away" feel
                
                if distance < interactionRadius {
                    let force = (interactionRadius - distance) / interactionRadius
                    // Impulse strength - needs to be high to overcome inertia
                    let pushStrength: CGFloat = 2.0 
                    
                    // Add impulse to current velocity
                    particles[i].velocityX += (distanceX / distance) * force * pushStrength
                    particles[i].velocityY += (distanceY / distance) * force * pushStrength
                }
            }
            
            // Move particle
            // Base movement modulated by energy + accumulated momentum
            particles[i].x += particles[i].velocityX * energyFactor
            particles[i].y += particles[i].velocityY * energyFactor
            
            // Damping / Return to normal
            // Slowly interpolate current velocity back to base velocity
            particles[i].velocityX = (particles[i].velocityX * damping) + (particles[i].baseVelocityX * returnStrength)
            particles[i].velocityY = (particles[i].velocityY * damping) + (particles[i].baseVelocityY * returnStrength)

            // Wrap around screen edges
            let margin: CGFloat = 50
            if particles[i].x < -margin {
                particles[i].x = screenWidth + margin
            } else if particles[i].x > screenWidth + margin {
                particles[i].x = -margin
            }
            
            if particles[i].y < -margin {
                particles[i].y = screenHeight + margin
            } else if particles[i].y > screenHeight + margin {
                particles[i].y = -margin
            }
        }
    }
}
