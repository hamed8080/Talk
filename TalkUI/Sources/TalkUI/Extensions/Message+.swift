import SwiftUI
import ChatModels

public extension Message {
    static let clockImage = UIImage(named: "clock")
    static let sentImage = UIImage(named: "single_chekmark")
    static let seenImage = UIImage(named: "double_checkmark")
    static let leadingTail = UIImage(named: "leading_tail")!
    static let trailingTail = UIImage(named: "trailing_tail")!
    static let emptyImage = UIImage(named: "empty_image")!

    var footerStatus: (image: UIImage, fgColor: Color) {
        if seen == true {
            return (Message.seenImage!, Color.App.accent)
        } else if delivered == true {
            return (Message.seenImage!, Color.App.textSecondary)
        } else if id != nil {
            return (Message.sentImage!, Color.App.textSecondary)
        } else {
            return (Message.clockImage!, Color.App.textSecondary)
        }
    }
}
