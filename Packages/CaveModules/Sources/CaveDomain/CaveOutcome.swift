public enum CaveOutcome: String, CaseIterable, Equatable, Sendable {
	case lostInDarkness
	case monsterAttack
	case fatalFall
	case cursedTreasure
	case escapeTreasurePortal

	public var isHappyEnding: Bool {
		self == .escapeTreasurePortal
	}
}
