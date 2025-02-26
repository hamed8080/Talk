public enum SearchParticipantType: String, CaseIterable, Identifiable, Sendable {
    public var id: Self { self }
    case name = "Participant.Search.Type.name"
    case username = "Participant.Search.Type.username"
    case cellphoneNumber = "Participant.Search.Type.cellphoneNumber"
    case admin = "Participant.Search.Type.admin"
}
