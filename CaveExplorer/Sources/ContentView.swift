import Combine
import SwiftUI

public struct ContentView: View {
    @StateObject private var game = CaveGame()
    @State private var lastTick = Date()
    private let timer = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common).autoconnect()

    public var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.40, green: 0.82, blue: 0.98), Color(red: 0.10, green: 0.31, blue: 0.67)],
                startPoint: .top,
                endPoint: .bottom
            )

            ForEach(game.pipes) { pipe in
                PipeView(
                    pipe: pipe,
                    worldSize: game.worldSize,
                    pipeWidth: game.pipeWidth,
                    gapHeight: game.gapHeight
                )
            }

            Circle()
                .fill(Color.yellow.gradient)
                .frame(width: game.birdRadius * 2, height: game.birdRadius * 2)
                .position(x: game.birdX, y: game.birdY)
                .shadow(radius: 2)

            VStack(spacing: 14) {
                Text("Score: \(game.score)")
                    .font(.system(size: 34, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.top, 14)

                Spacer()

                if game.isGameOver {
                    Text("Game Over")
                        .font(.largeTitle.bold())
                        .foregroundStyle(.white)
                    Text("Haz click o presiona el boton para reiniciar")
                        .foregroundStyle(.white.opacity(0.92))
                } else if !game.hasStarted {
                    Text("Haz click dentro del juego para aletear")
                        .foregroundStyle(.white.opacity(0.92))
                }

                Button(game.isGameOver ? "Reiniciar" : "Aletear") {
                    game.flap()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(.bottom, 14)
            }
            .padding(.horizontal, 18)
        }
        .frame(width: game.worldSize.width, height: game.worldSize.height)
        .clipShape(.rect(cornerRadius: 22))
        .overlay {
            RoundedRectangle(cornerRadius: 22)
                .stroke(.white.opacity(0.6), lineWidth: 2)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            game.flap()
        }
        .onReceive(timer) { now in
            let rawDelta = now.timeIntervalSince(lastTick)
            let dt = max(0, min(rawDelta, 1.0 / 20.0))
            lastTick = now
            game.update(deltaTime: dt)
        }
        .onAppear {
            lastTick = Date()
        }
        .padding(24)
        .background(Color.black.opacity(0.9))
    }
}

private struct PipeView: View {
    let pipe: CaveGame.Pipe
    let worldSize: CGSize
    let pipeWidth: CGFloat
    let gapHeight: CGFloat

    var body: some View {
        let topHeight = max(0, pipe.gapCenterY - gapHeight * 0.5)
        let bottomY = pipe.gapCenterY + gapHeight * 0.5
        let bottomHeight = max(0, worldSize.height - bottomY)

        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.green.gradient)
                .frame(width: pipeWidth, height: topHeight)
                .position(x: pipe.x, y: topHeight * 0.5)

            RoundedRectangle(cornerRadius: 10)
                .fill(Color.green.gradient)
                .frame(width: pipeWidth, height: bottomHeight)
                .position(x: pipe.x, y: bottomY + (bottomHeight * 0.5))
        }
    }
}
