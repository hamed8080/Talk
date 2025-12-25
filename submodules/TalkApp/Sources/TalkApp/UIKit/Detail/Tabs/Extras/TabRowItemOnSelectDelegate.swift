//
//  TabRowItemOnSelectDelegate.swift
//  TalkApp
//
//  Created by Hamed Hosseini on 12/23/25.
//

import UIKit
import TalkViewModels

@MainActor
public protocol TabRowItemOnSelectDelegate: AnyObject {
    func onSelect(item: TabRowModel)
}

@MainActor
public protocol TabControllerDelegate: AnyObject {
    var onSelectDelegate: TabRowItemOnSelectDelegate? { get set }
    var detailVM: ThreadDetailViewModel? { get set }
}
