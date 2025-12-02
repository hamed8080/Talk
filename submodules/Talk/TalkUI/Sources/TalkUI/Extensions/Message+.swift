import SwiftUI
import Chat
import TalkExtensions
import TalkModels


public extension HistoryMessageProtocol {
    func footerStatus(isUploading: Bool) -> (image: UIImage, fgColor: Color) {
        if seen == true {
            return (MessageHistoryStatics.seenImage!, Color.App.accent)
            //        } else if delivered == true {
            //            return (Message.seenImage!, Color.App.textPrimary.opacity(0.6))
        } else if id != nil && !isUploading {
            return (MessageHistoryStatics.sentImage!, Color.App.textPrimary.opacity(0.6))
        } else {
            return (MessageHistoryStatics.clockImage!, Color.App.textPrimary.opacity(0.6))
        }
    }

    var uiFooterStatus: (image: UIImage, fgColor: UIColor) {
        if seen == true {
            return (MessageHistoryStatics.seenImage!, Color.App.textPrimaryUIColor!)
//        } else if delivered == true {
//            return (MessageHistoryStatics.seenImage!, Color.App.textSecondaryUIColor!)
        } else if id != nil, !(self is UploadProtocol) {
            return (MessageHistoryStatics.sentImagePadding!, Color.App.textSecondaryUIColor!)
        } else {
            return (MessageHistoryStatics.clockImage!, Color.App.textPrimaryUIColor!.withAlphaComponent(0.6))
        }
    }
}
