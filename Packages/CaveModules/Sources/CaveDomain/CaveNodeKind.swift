public enum CaveNodeKind: Equatable, Sendable {
	case corridor
	case junction(optionCount: Int)
	case ending(CaveOutcome)
}
