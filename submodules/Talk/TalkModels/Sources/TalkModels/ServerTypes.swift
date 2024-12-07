public enum ServerTypes: String, CaseIterable, Identifiable, Sendable {
    public var id: Self { self }
    case main
    case sandbox
    case integration
}
