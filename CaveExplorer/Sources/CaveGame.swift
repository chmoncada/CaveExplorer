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
	private var elapsedRunTime: TimeInterval = 0
	private var decisionsTaken = 0

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

	var currentSeed: UInt64? {
		activeConfig.randomSeed
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

	var runSummary: CaveRunSummary? {
		guard case .ended(let outcome) = runState?.phase else { return nil }
		return CaveRunSummary(
			outcome: outcome,
			reachedDepth: currentDepth,
			maxDepth: maxDepth,
			estimatedDuration: elapsedRunTime,
			seed: activeConfig.randomSeed,
			decisionsTaken: decisionsTaken
		)
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
		elapsedRunTime = 0
		decisionsTaken = 0

		let graph = generator.generate(config: nextConfig)
		mapGraph = graph

		let engine = CaveRunEngine(graph: graph, config: nextConfig)
		apply(engine: engine)
	}

	func tick(deltaTime: TimeInterval) {
		guard var engine = runEngine else { return }
		guard case .ended = runState?.phase else {
			elapsedRunTime += max(0, deltaTime)
			engine.tick(deltaTime: deltaTime)
			apply(engine: engine)
			return
		}
		engine.tick(deltaTime: deltaTime)
		apply(engine: engine)
	}

	func choose(optionIndex: Int) {
		guard var engine = runEngine else { return }
		guard engine.choose(optionIndex: optionIndex) else { return }
		decisionsTaken += 1
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

struct CaveRunSummary: Equatable {
	let outcome: CaveOutcome
	let reachedDepth: Int
	let maxDepth: Int
	let estimatedDuration: TimeInterval
	let seed: UInt64?
	let decisionsTaken: Int

	init(
		outcome: CaveOutcome,
		reachedDepth: Int,
		maxDepth: Int,
		estimatedDuration: TimeInterval = 0,
		seed: UInt64? = nil,
		decisionsTaken: Int = 0
	) {
		self.outcome = outcome
		self.reachedDepth = reachedDepth
		self.maxDepth = maxDepth
		self.estimatedDuration = estimatedDuration
		self.seed = seed
		self.decisionsTaken = decisionsTaken
	}

	var isSuccessful: Bool {
		outcome == .escapeTreasurePortal
	}

	var progressRatio: Double {
		guard maxDepth > 0 else { return 0 }
		let ratio = Double(reachedDepth) / Double(maxDepth)
		return min(1, max(0, ratio))
	}

	var progressPercent: Int {
		Int((progressRatio * 100).rounded())
	}

	var headline: String {
		isSuccessful ? "Escapaste de la cueva" : "La expedicion termino"
	}

	var depthLine: String {
		"Profundidad alcanzada: \(reachedDepth) / \(maxDepth) (\(progressPercent)%)"
	}

	var outcomeTitle: String {
		outcome.screenTitle
	}

	var outcomeSubtitle: String {
		outcome.screenSubtitle
	}

	var statusLabel: String {
		isSuccessful ? "Escape confirmado" : "Run terminada"
	}

	var recommendedNextAction: String {
		if isSuccessful {
			return "Prueba otra seed o sube la dificultad."
		}
		return "Reintenta rapido o ajusta tus settings antes de bajar otra vez."
	}

	var estimatedDurationLine: String {
		let seconds = estimatedDuration.formatted(.number.precision(.fractionLength(1)))
		return "Tiempo estimado: \(seconds)s"
	}

	var seedLine: String {
		if let seed {
			return "Seed: \(seed)"
		}
		return "Seed: aleatoria"
	}

	var decisionsLine: String {
		"Decisiones tomadas: \(decisionsTaken)"
	}
}

struct CaveRunStats: Equatable {
	var bestDepth: Int
	var escapedRuns: Int

	static let empty = CaveRunStats(bestDepth: 0, escapedRuns: 0)

	var normalized: CaveRunStats {
		CaveRunStats(bestDepth: max(0, bestDepth), escapedRuns: max(0, escapedRuns))
	}

	func recording(_ summary: CaveRunSummary) -> CaveRunStats {
		let current = normalized
		return CaveRunStats(
			bestDepth: max(current.bestDepth, summary.reachedDepth),
			escapedRuns: current.escapedRuns + (summary.isSuccessful ? 1 : 0)
		).normalized
	}
}

struct CaveRunRecord: Codable, Equatable, Identifiable {
	static let storedHistoryLimit = 5
	static let homeVisibleLimit = 3

	let id: UUID
	let endedAt: Date
	let outcomeTitle: String
	let reachedDepth: Int
	let maxDepth: Int
	let progressPercent: Int
	let estimatedDuration: TimeInterval
	let decisionsTaken: Int
	let seed: UInt64?
	let isSuccessful: Bool

	init(summary: CaveRunSummary, endedAt: Date = .now) {
		self.id = UUID()
		self.endedAt = endedAt
		self.outcomeTitle = summary.outcomeTitle
		self.reachedDepth = summary.reachedDepth
		self.maxDepth = summary.maxDepth
		self.progressPercent = summary.progressPercent
		self.estimatedDuration = summary.estimatedDuration
		self.decisionsTaken = summary.decisionsTaken
		self.seed = summary.seed
		self.isSuccessful = summary.isSuccessful
	}

	var durationLine: String {
		let seconds = estimatedDuration.formatted(.number.precision(.fractionLength(1)))
		return "\(seconds)s | \(decisionsTaken) decisiones"
	}

	var seedLine: String {
		if let seed {
			return "Seed \(seed)"
		}
		return "Seed aleatoria"
	}

	static func appending(
		summary: CaveRunSummary,
		to records: [CaveRunRecord],
		limit: Int = CaveRunRecord.storedHistoryLimit
	) -> [CaveRunRecord] {
		let next = CaveRunRecord(summary: summary)
		return Array(([next] + records).prefix(max(1, limit)))
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
