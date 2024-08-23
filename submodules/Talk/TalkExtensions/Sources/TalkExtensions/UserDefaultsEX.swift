import Foundation
public extension UserDefaults {
    static let group = UserDefaults(suiteName: AppGroup.group)
}
