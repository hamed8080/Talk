//
//  ActionItemModel.swift
//  Talk
//
//  Created by hamed on 6/30/24.
//

import Foundation
import UIKit

public struct ActionItemModel {
    let title: String
    let image: String?
    let color: UIColor
    let sandbox: Bool

    public init(title: String, image: String?, color: UIColor = UIColor(named: "text_primary")!, sandbox: Bool = false) {
        self.title = title.bundleLocalized()
        self.image = image
        self.color = color
        self.sandbox = sandbox
    }
}

public extension ActionItemModel {
    nonisolated(unsafe) static let reply = ActionItemModel(title: "Messages.ActionMenu.reply", image:  "arrowshape.turn.up.left")
    nonisolated(unsafe) static let replyPrivately = ActionItemModel(title: "Messages.ActionMenu.replyPrivately", image: "arrow.up.forward.app")
    nonisolated(unsafe) static let forward = ActionItemModel(title: "Messages.ActionMenu.forward", image: "arrowshape.turn.up.right")
    nonisolated(unsafe) static let edit = ActionItemModel(title: "General.edit", image: "pencil.circle")
    nonisolated(unsafe) static let add = ActionItemModel(title: "General.addText", image: "pencil.circle")
    nonisolated(unsafe) static let messageDetail = ActionItemModel(title: "Messages.ActionMenu.messageDetail", image: "eye")
    nonisolated(unsafe) static let saveImage = ActionItemModel(title: "Messages.ActionMenu.saveImage", image: "square.and.arrow.down")
    nonisolated(unsafe) static let saveVideo = ActionItemModel(title: "Messages.ActionMenu.saveImage", image: "square.and.arrow.down")
    nonisolated(unsafe) static let copy = ActionItemModel(title: "Messages.ActionMenu.copy", image: "doc.on.doc")
    nonisolated(unsafe) static let share = ActionItemModel(title: "Messages.ActionMenu.share", image: "square.and.arrow.up")
    nonisolated(unsafe) static let deleteCache = ActionItemModel(title: "Messages.ActionMenu.deleteCache", image: "cylinder.split.1x2", sandbox: true)
    nonisolated(unsafe) static let reDownload = ActionItemModel(title: "Messages.ActionMenu.reDownload", image: "arrow.trianglehead.counterclockwise.rotate.90")
    nonisolated(unsafe) static let pin = ActionItemModel(title: "Messages.ActionMenu.pinMessage", image: "pin")
    nonisolated(unsafe) static let unpin = ActionItemModel(title: "Messages.ActionMenu.unpinMessage", image: "pin.slash")
    nonisolated(unsafe) static let select = ActionItemModel(title: "General.select", image: "checkmark.circle")
    nonisolated(unsafe) static let delete = ActionItemModel(title: "General.delete", image: "trash", color: .systemRed)
    nonisolated(unsafe) static func debugPrint(id: Int) -> ActionItemModel { ActionItemModel(title: "\(id)", image: "info", sandbox: true) }
}
