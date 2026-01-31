//
//  MessagCallTextCalculator.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 1/11/26.
//

import Foundation
import UIKit
import TalkModels

public final class MessagCallTextCalculator {
    private let message: HistoryMessageType
    private let myId: Int?
    
    public init(message: HistoryMessageType, myId: Int?) {
        self.message = message
        self.myId = myId
    }
    
    func attribute() -> NSAttributedString? {
        if ![.endCall, .startCall].contains(message.type) { return nil }
        guard let time = message.time else { return nil }
        
        let status = message.callHistory?.status
        let isCallStarter = message.participant?.id == myId
        
        let isStarted = message.type == .startCall
        let isMissed = status == .declined || status == .miss
        let isCanceled = status == .canceled && isCallStarter
        let isDeclined = status == .canceled && !isCallStarter
        let isEnded = status == .ended
        
        let attr = NSMutableAttributedString()
        let imageName = isStarted ? "phone.fill" : isMissed ? "phone.arrow.up.right.fill" : "phone.down.fill"
        let image = UIImage(systemName: imageName)?.withRenderingMode(.alwaysTemplate).withTintColor(isStarted ? .green : .red) ?? UIImage()
        let imgAttachment = NSTextAttachment(image: image)
        let attachmentAttribute = NSAttributedString(attachment: imgAttachment)
        attr.append(attachmentAttribute)
        
        let date = Date(milliseconds: Int64(isStarted ? (message.callHistory?.startTime ?? time) : (message.callHistory?.endTime ?? time)))
        let hour = MessageRowCalculators.hourFormatter.string(from: date)
        
        var formattedString = ""
        if isStarted || isMissed || isCanceled {
            let key = isStarted ? "Thread.callAccepted" : isMissed ? "Thread.callMissed" : "Thread.callCanceled"
            formattedString = String(format: key.bundleLocalized(), hour)
        } else if isDeclined {
            let decliner = message.participant?.name ?? ""
            let cancelText = "Thread.callDeclined".bundleLocalized()
            formattedString = String(format: cancelText, decliner, hour)
        } else if isEnded {
            let duration = (message.callHistory?.endTime ?? 0) - (message.callHistory?.startTime ?? 0)
            let seconds = duration / 1000
            let durationString = seconds.timerStringTripleSection(locale: Language.preferredLocale) ?? ""
            
            let endText = "Thread.callEnded".bundleLocalized()
            formattedString = String(format: endText, hour, durationString)
        }
        
        let textAttr = NSMutableAttributedString(string: " \(formattedString)")
        attr.append(textAttr)
        return attr
    }
}
