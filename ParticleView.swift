import SwiftUI

struct Particle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat
    var opacity: Double
    var velocityX: CGFloat
    var velocityY: CGFloat
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
        particles = (0..<60).map { _ in
            createRandomParticle(screenWidth: screenWidth, screenHeight: screenHeight)
        }
    }
    
    private func createRandomParticle(screenWidth: CGFloat, screenHeight: CGFloat) -> Particle {
        return Particle(
            x: CGFloat.random(in: 0...screenWidth),
            y: CGFloat.random(in: 0...screenHeight),
            size: CGFloat.random(in: 10...30), // Larger, softer particles
            opacity: Double.random(in: 0.3...0.7),
            velocityX: CGFloat.random(in: -0.5...0.5),
            velocityY: CGFloat.random(in: -0.5...0.5),
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
            // Apply velocity with energy
            var dx = particles[i].velocityX * energyFactor
            var dy = particles[i].velocityY * energyFactor
            
            // Interaction with touch
            if touchLocation != .zero {
                let particleCenter = CGPoint(x: particles[i].x + particles[i].size / 2, y: particles[i].y + particles[i].size / 2)
                let distanceX = particleCenter.x - touchLocation.x
                let distanceY = particleCenter.y - touchLocation.y
                let distance = sqrt(distanceX * distanceX + distanceY * distanceY)
                
                let interactionRadius: CGFloat = 150.0
                
                if distance < interactionRadius {
                    let force = (interactionRadius - distance) / interactionRadius
                    let repulsionStrength: CGFloat = 5.0 // Adjust strength of repulsion
                    
                    dx += (distanceX / distance) * force * repulsionStrength
                    dy += (distanceY / distance) * force * repulsionStrength
                }
            }
            
            particles[i].x += dx
            particles[i].y += dy
            
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
