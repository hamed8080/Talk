import Chat

public struct SideBarItem: Identifiable, Hashable, Sendable {
    public var id: String
    public var tag: Tag?
    public var title: String
    public var icon: String

    public init(id: String, tag: Tag? = nil, title: String, icon: String) {
        self.id = id
        self.tag = tag
        self.title = title
        self.icon = icon
    }
}
