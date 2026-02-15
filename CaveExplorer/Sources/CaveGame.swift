import Combine
import CoreGraphics
import Foundation

@MainActor
final class CaveGame: ObservableObject {
    struct Pipe: Identifiable {
        let id = UUID()
        var x: CGFloat
        var gapCenterY: CGFloat
        var scored = false
    }

    let worldSize = CGSize(width: 900, height: 640)
    let birdX: CGFloat = 220
    let birdRadius: CGFloat = 16
    let pipeWidth: CGFloat = 70
    let gapHeight: CGFloat = 180
    let gravity: CGFloat = 1100
    let flapImpulse: CGFloat = -380
    let scrollSpeed: CGFloat = 220
    let pipeSpacing: CGFloat = 280

    @Published private(set) var birdY: CGFloat = 0
    @Published private(set) var velocity: CGFloat = 0
    @Published private(set) var score = 0
    @Published private(set) var hasStarted = false
    @Published private(set) var isGameOver = false
    @Published private(set) var pipes: [Pipe] = []

    init() {
        reset()
    }

    func reset() {
        birdY = worldSize.height * 0.5
        velocity = 0
        score = 0
        hasStarted = false
        isGameOver = false

        let startX = worldSize.width + 140
        pipes = (0..<4).map { index in
            Pipe(
                x: startX + (CGFloat(index) * pipeSpacing),
                gapCenterY: randomGapCenterY(),
                scored: false
            )
        }
    }

    func flap() {
        if isGameOver {
            reset()
            hasStarted = true
        } else if !hasStarted {
            hasStarted = true
        }

        velocity = flapImpulse
    }

    func update(deltaTime: TimeInterval) {
        guard hasStarted, !isGameOver else { return }

        let dt = CGFloat(deltaTime)
        velocity += gravity * dt
        birdY += velocity * dt

        for index in pipes.indices {
            pipes[index].x -= scrollSpeed * dt

            if !pipes[index].scored && (pipes[index].x + pipeWidth * 0.5) < birdX {
                pipes[index].scored = true
                score += 1
            }

            if pipes[index].x < -pipeWidth {
                let maxX = pipes.map(\.x).max() ?? worldSize.width
                pipes[index].x = maxX + pipeSpacing
                pipes[index].gapCenterY = randomGapCenterY()
                pipes[index].scored = false
            }
        }

        checkCollisions()
    }

    private func randomGapCenterY() -> CGFloat {
        CGFloat.random(in: 130...(worldSize.height - 130))
    }

    private func checkCollisions() {
        let birdRect = CGRect(
            x: birdX - birdRadius,
            y: birdY - birdRadius,
            width: birdRadius * 2,
            height: birdRadius * 2
        )

        if birdRect.minY <= 0 || birdRect.maxY >= worldSize.height {
            isGameOver = true
            return
        }

        for pipe in pipes {
            let gapTop = pipe.gapCenterY - gapHeight * 0.5
            let gapBottom = pipe.gapCenterY + gapHeight * 0.5
            let xStart = pipe.x - pipeWidth * 0.5

            let topRect = CGRect(x: xStart, y: 0, width: pipeWidth, height: gapTop)
            let bottomRect = CGRect(
                x: xStart,
                y: gapBottom,
                width: pipeWidth,
                height: worldSize.height - gapBottom
            )

            if topRect.intersects(birdRect) || bottomRect.intersects(birdRect) {
                isGameOver = true
                return
            }
        }
    }
}
