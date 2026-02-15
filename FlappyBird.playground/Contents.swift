import Combine
import Observation
import PlaygroundSupport
import SwiftUI

@MainActor
@Observable
final class FlappyGame {
    struct Pipe: Identifiable {
        let id = UUID()
        var x: CGFloat
        var gapCenterY: CGFloat
        var scored = false
    }

    let size = CGSize(width: 420, height: 640)
    let birdX: CGFloat = 110
    let birdRadius: CGFloat = 16
    let pipeWidth: CGFloat = 60
    let gapHeight: CGFloat = 170
    let gravity: CGFloat = 900
    let flapImpulse: CGFloat = -320
    let scrollSpeed: CGFloat = 130

    var birdY: CGFloat = 0
    var velocity: CGFloat = 0
    var score = 0
    var hasStarted = false
    var isGameOver = false
    var pipes: [Pipe] = []

    private var lastUpdate = Date()

    init() {
        reset()
    }

    func reset() {
        birdY = size.height * 0.5
        velocity = 0
        score = 0
        hasStarted = false
        isGameOver = false
        lastUpdate = Date()

        let startX: CGFloat = size.width + 120
        let spacing: CGFloat = 180
        pipes = (0..<3).map { index in
            Pipe(
                x: startX + (CGFloat(index) * spacing),
                gapCenterY: randomGapCenterY()
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

    func update(now: Date) {
        let rawDelta = now.timeIntervalSince(lastUpdate)
        let dt = max(0, min(rawDelta, 1.0 / 20.0))
        lastUpdate = now

        guard hasStarted, !isGameOver else { return }

        velocity += gravity * dt
        birdY += velocity * dt

        for index in pipes.indices {
            pipes[index].x -= scrollSpeed * dt

            if !pipes[index].scored && (pipes[index].x + pipeWidth * 0.5) < birdX {
                pipes[index].scored = true
                score += 1
            }

            if pipes[index].x < -pipeWidth {
                let maxX = pipes.map(\.x).max() ?? size.width
                pipes[index].x = maxX + 180
                pipes[index].gapCenterY = randomGapCenterY()
                pipes[index].scored = false
            }
        }

        checkCollisions()
    }

    private func randomGapCenterY() -> CGFloat {
        CGFloat.random(in: 130...(size.height - 130))
    }

    private func checkCollisions() {
        let birdRect = CGRect(
            x: birdX - birdRadius,
            y: birdY - birdRadius,
            width: birdRadius * 2,
            height: birdRadius * 2
        )

        if birdRect.minY <= 0 || birdRect.maxY >= size.height {
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
                height: size.height - gapBottom
            )

            if topRect.intersects(birdRect) || bottomRect.intersects(birdRect) {
                isGameOver = true
                return
            }
        }
    }
}

struct FlappyGameView: View {
    @State private var game = FlappyGame()
    private let timer = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [.cyan.opacity(0.35), .blue.opacity(0.7)],
                startPoint: .top,
                endPoint: .bottom
            )

            ForEach(game.pipes) { pipe in
                PipeShape(
                    pipeX: pipe.x,
                    gapCenterY: pipe.gapCenterY,
                    width: game.pipeWidth,
                    gapHeight: game.gapHeight,
                    canvasSize: game.size
                )
                .fill(.green.gradient)
                .shadow(radius: 1)
            }

            Circle()
                .fill(.yellow.gradient)
                .frame(width: game.birdRadius * 2, height: game.birdRadius * 2)
                .position(x: game.birdX, y: game.birdY)
                .shadow(radius: 2)

            VStack {
                Text("Score: \(game.score)")
                    .font(.system(size: 26, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.top, 20)

                Spacer()

                if game.isGameOver {
                    Text("Game Over")
                        .font(.title.bold())
                        .foregroundStyle(.white)
                } else if !game.hasStarted {
                    Text("Presiona el boton para empezar")
                        .foregroundStyle(.white.opacity(0.9))
                }

                Button(game.isGameOver ? "Reiniciar" : "Aletear") {
                    game.flap()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(.bottom, 24)
            }
        }
        .frame(width: game.size.width, height: game.size.height)
        .clipShape(.rect(cornerRadius: 20))
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .stroke(.white.opacity(0.55), lineWidth: 2)
        }
        .onReceive(timer) { now in
            game.update(now: now)
        }
        .padding(20)
        .background(.black.opacity(0.92))
    }
}

struct PipeShape: Shape {
    let pipeX: CGFloat
    let gapCenterY: CGFloat
    let width: CGFloat
    let gapHeight: CGFloat
    let canvasSize: CGSize

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let xStart = pipeX - width * 0.5
        let topHeight = gapCenterY - gapHeight * 0.5
        let bottomY = gapCenterY + gapHeight * 0.5

        path.addRoundedRect(
            in: CGRect(x: xStart, y: 0, width: width, height: max(0, topHeight)),
            cornerSize: CGSize(width: 8, height: 8)
        )

        path.addRoundedRect(
            in: CGRect(
                x: xStart,
                y: bottomY,
                width: width,
                height: max(0, canvasSize.height - bottomY)
            ),
            cornerSize: CGSize(width: 8, height: 8)
        )

        return path
    }
}

PlaygroundPage.current.needsIndefiniteExecution = true
PlaygroundPage.current.setLiveView(FlappyGameView())
