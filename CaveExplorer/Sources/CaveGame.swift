import CaveDomain
import CaveGameplay
import CaveMapEngine
import Foundation
import Observation

@MainActor
@Observable
final class CaveSession {
	struct Choice: Identifiable, Equatable {
		let optionIndex: Int
		let title: String

		var id: Int { optionIndex }
	}

	private let generator: CaveMapGenerator
	private var baseConfig: CaveConfig

	private var activeConfig: CaveConfig
	private var runEngine: CaveRunEngine?
	private var mapGraph: CaveMapGraph?

	private(set) var runState: CaveRunState?
	private(set) var choices: [Choice] = []

	init(
		config: CaveConfig = CaveGameSettings.default.caveConfig,
		generator: CaveMapGenerator = CaveMapGenerator()
	) {
		self.baseConfig = config
		self.activeConfig = config
		self.generator = generator

		startNewGame(seed: config.randomSeed)
	}

	var maxDepth: Int {
		activeConfig.maxDepth
	}

	var currentDepth: Int {
		runState?.currentDepth ?? 0
	}

	var depthProgress: Double {
		guard maxDepth > 0 else { return 0 }
		return min(1, max(0, Double(currentDepth) / Double(maxDepth)))
	}

	var travelProgress: Double? {
		guard case .traveling(let travel) = runState?.phase else { return nil }
		return travel.progress
	}

	var decisionRemainingRatio: Double? {
		guard case .waitingForChoice(let decision) = runState?.phase, decision.totalTime > 0 else {
			return nil
		}
		return min(1, max(0, decision.remainingTime / decision.totalTime))
	}

	var titleText: String {
		guard let runState else { return "Preparando expedicion..." }

		switch runState.phase {
		case .traveling:
			return "Avanzando por el tunel"
		case .waitingForChoice:
			return "Encrucijada"
		case .ended(let outcome):
			return outcome.screenTitle
		}
	}

	var subtitleText: String {
		guard let runState else { return "Generando nuevo mapa..." }

		switch runState.phase {
		case .traveling:
			return "La antorcha apenas ilumina el camino."
		case .waitingForChoice:
			return "Elige una entrada antes de que te alcance el monstruo."
		case .ended(let outcome):
			return outcome.screenSubtitle
		}
	}

	var isGameOver: Bool {
		guard case .ended = runState?.phase else { return false }
		return true
	}

	func applySettings(_ settings: CaveGameSettings) {
		let config = settings.caveConfig
		baseConfig = config
		startNewGame(seed: config.randomSeed)
	}

	func startNewGame(seed: UInt64? = nil) {
		var nextConfig = baseConfig
		nextConfig.randomSeed = seed
		activeConfig = nextConfig

		let graph = generator.generate(config: nextConfig)
		mapGraph = graph

		let engine = CaveRunEngine(graph: graph, config: nextConfig)
		apply(engine: engine)
	}

	func tick(deltaTime: TimeInterval) {
		guard var engine = runEngine else { return }
		engine.tick(deltaTime: deltaTime)
		apply(engine: engine)
	}

	func choose(optionIndex: Int) {
		guard var engine = runEngine else { return }
		guard engine.choose(optionIndex: optionIndex) else { return }
		apply(engine: engine)
	}

	private func apply(engine: CaveRunEngine) {
		runEngine = engine
		runState = engine.state
		refreshChoices()
	}

	private func refreshChoices() {
		guard
			case .waitingForChoice(let decision) = runState?.phase,
			let node = mapGraph?.nodes[decision.nodeID]
		else {
			choices = []
			return
		}

		choices = node.childNodeIDs.indices.map { index in
			Choice(optionIndex: index, title: choiceTitle(for: index, total: node.childNodeIDs.count))
		}
	}

	private func choiceTitle(for index: Int, total: Int) -> String {
		switch total {
		case 2:
			return index == 0 ? "Izquierda" : "Derecha"
		case 3:
			switch index {
			case 0:
				return "Izquierda"
			case 1:
				return "Centro"
			default:
				return "Derecha"
			}
		default:
			return "Entrada \(index + 1)"
		}
	}
}

extension CaveOutcome {
	fileprivate var screenTitle: String {
		switch self {
		case .lostInDarkness:
			return "Te perdiste en la oscuridad"
		case .monsterAttack:
			return "El monstruo te alcanzo"
		case .fatalFall:
			return "Caida al precipicio"
		case .cursedTreasure:
			return "Trampa mortal"
		case .escapeTreasurePortal:
			return "Tesoro encontrado"
		}
	}

	fileprivate var screenSubtitle: String {
		switch self {
		case .lostInDarkness:
			return "La antorcha se apago y no encontraste salida."
		case .monsterAttack:
			return "Dudaste demasiado en la encrucijada."
		case .fatalFall:
			return "Un paso falso fue suficiente para caer."
		case .cursedTreasure:
			return "El tesoro estaba protegido por una trampa."
		case .escapeTreasurePortal:
			return "Conseguiste el portal y escapaste de la cueva."
		}
	}
}
