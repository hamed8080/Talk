public enum ServerTypes: String, CaseIterable, Identifiable {
    public var id: Self { self }
    case main
    case sandbox
    case integration
}
