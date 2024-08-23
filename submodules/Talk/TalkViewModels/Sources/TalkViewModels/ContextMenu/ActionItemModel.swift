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

    public init(title: String, image: String?, color: UIColor = UIColor(named: "text_primary")!) {
        self.title = title.bundleLocalized()
        self.image = image
        self.color = color
    }
}

public extension ActionItemModel {
    static let reply = ActionItemModel(title: "Messages.ActionMenu.reply", image:  "arrowshape.turn.up.left")
    static let replyPrivately = ActionItemModel(title: "Messages.ActionMenu.replyPrivately", image: "arrowshape.turn.up.left")
    static let forward = ActionItemModel(title: "Messages.ActionMenu.forward", image: "arrowshape.turn.up.right")
    static let edit = ActionItemModel(title: "General.edit", image: "pencil.circle")
    static let add = ActionItemModel(title: "General.addText", image: "pencil.circle")
    static let seenParticipants = ActionItemModel(title: "SeenParticipants.title", image: "info.bubble")
    static let saveImage = ActionItemModel(title: "Messages.ActionMenu.saveImage", image: "square.and.arrow.down")
    static let saveVideo = ActionItemModel(title: "Messages.ActionMenu.saveImage", image: "square.and.arrow.down")
    static let copy = ActionItemModel(title: "Messages.ActionMenu.copy", image: "doc.on.doc")
    static let deleteCache = ActionItemModel(title: "Messages.ActionMenu.deleteCache", image: "cylinder.split.1x2")
    static let pin = ActionItemModel(title: "Messages.ActionMenu.pinMessage", image: "pin")
    static let unpin = ActionItemModel(title: "Messages.ActionMenu.unpinMessage", image: "pin.slash")
    static let select = ActionItemModel(title: "General.select", image: "checkmark.circle")
    static let delete = ActionItemModel(title: "General.delete", image: "trash", color: .systemRed)
}
