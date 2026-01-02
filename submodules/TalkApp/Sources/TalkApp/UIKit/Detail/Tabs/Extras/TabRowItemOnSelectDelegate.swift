//
//  TabRowItemOnSelectDelegate.swift
//  TalkApp
//
//  Created by Hamed Hosseini on 12/23/25.
//

import UIKit
import TalkViewModels
import Chat

@MainActor
public protocol UIChildViewScrollDelegate: AnyObject {
    func onChildViewDidScrolled(_ scrollView: UIScrollView)
}

@MainActor
public protocol TabRowItemOnSelectDelegate: AnyObject {
    func onSelect(item: TabRowModel)
    func onSelectMutualGroup(conversation: Conversation)
}

@MainActor
public protocol UIViewControllerScrollDelegate {
    func getInternalScrollView() -> UIScrollView
}

@MainActor
public protocol TabControllerDelegate: AnyObject {
    var scrollDelegate: UIChildViewScrollDelegate? { get set }
    var onSelectDelegate: TabRowItemOnSelectDelegate? { get set }
    var detailVM: ThreadDetailViewModel? { get set }
}
