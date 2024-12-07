import Foundation
public extension UserDefaults {
    nonisolated(unsafe) static let group = UserDefaults(suiteName: AppGroup.group)
}
