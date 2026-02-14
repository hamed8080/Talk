//
//  HistoryContentInsetManager.swift
//  TalkApp
//
//  Created by Hamed Hosseini on 2/11/26.
//

import UIKit

@MainActor
class HistoryContentInsetManager {
    private let vc: ThreadViewController
    
    private var tableView: UIHistoryTableView { vc.tableView }
    
    init(controller: ThreadViewController) {
        self.vc = controller
    }
    
    private var keyboardHeight: CGFloat { vc.keyboardManager.getKeyboardHeight() }
    private var sendContainer: ThreadBottomToolbar { vc.sendContainer }
    private var topThreadToolbar: TopThreadToolbar { vc.topThreadToolbar }
    private var view: UIView { vc.view }
    
    func updateContentInset(methodName: String) {
        /// Order do matter firstly we need to calculate bottom then we use calculated bottom constant.
        setBottomContentInset()
        setTopContentInset()
        tableView.scrollIndicatorInsets = tableView.contentInset
        printContentInset(methodName: methodName)
        
        let isSmaller = isContentSmallerThanHeight()
        if isSmaller {
            tableView.beginUpdates()
            tableView.endUpdates()
        }
    }
    
    func bottomContainerHeight() -> CGFloat {
        let spaceLastMessage = ConstantSizes.spaceLastMessageAndBottomContainer
        let height = vc.sendContainer.bounds.height
        return keyboardHeight + height + spaceLastMessage
    }
    
    private func isContentSmallerThanHeight() -> Bool {
        if vc.viewModel.historyVM.sections.isEmpty {
            return false
        }
        let bottom = sendContainer.bounds.height - sendContainer.safeAreaInsets.bottom
        return tableView.contentSize.height < tableView.frame.height - (bottom + topToolbarHeight())
    }
    
    private func topToolbarHeight() -> CGFloat {
        topThreadToolbar.bounds.height
    }
    
    private func diffTableViewContentSizeAndFrameHeight() -> CGFloat {
        let spaceLastMessage = ConstantSizes.spaceLastMessageAndBottomContainer
        
        /// Send contianer height contains an effect view where it passes bottom safe area,
        /// so it has sendContainer.height + view.safeAreaInsets.bottom
        let sendContainerHeight = sendContainer.frame.height

        var remain = tableView.frame.height
        remain -= topToolbarHeight()
        remain -= tableView.contentSize.height
        remain -= sendContainerHeight
        remain -= spaceLastMessage
        remain -= keyboardHeight
        remain += topToolbarHeight()
        return remain
    }
    
    private func setTopContentInset() {
        let isSmaller = isContentSmallerThanHeight()
        let topToolbarInset = topToolbarHeight()
        /// We use contentInsetAdjustmentBehavior = .automatic in UIHistoryTableView
        /// so safearea content inset for top and bottom will be calculated automatically and we have to make sure to remove it.
        let topSafeArea = view.safeAreaInsets.top
        let top = isSmaller ? diffTableViewContentSizeAndFrameHeight() - topSafeArea : topToolbarInset - topSafeArea
        if tableView.contentInset.top != top {
            tableView.contentInset.top = top
        }
    }
    
    private func setBottomContentInset() {
        let bottomHeight = bottomContainerHeight()
        /// We use contentInsetAdjustmentBehavior = .automatic in UIHistoryTableView
        /// so safearea content inset for top and bottom will be calculated automatically and we have to make sure to remove it.
        let bottomSafeArea = view.safeAreaInsets.bottom
        let bottom = bottomHeight - bottomSafeArea
        if tableView.contentInset.bottom != bottom {
            tableView.contentInset.bottom = bottom
        }
    }
    
    private func printContentInset(methodName: String) {
        log(
            """
[CONTENT_INSET] in \(methodName)
TableView ContentInset: \(tableView.contentInset)
TableView ContentSize: \(tableView.contentSize)
TableView Frame: \(tableView.frame)
View top safe area: \(view.safeAreaInsets.top)
View bottom safe area : \(view.safeAreaInsets.bottom)
TopThreadToolbar Bounds: \(topThreadToolbar.bounds)
TopThreadToolbar Frame: \(topThreadToolbar.frame)
SendContainer Bounds: \(sendContainer.bounds)
SendContainer Frame: \(sendContainer.frame)
Keyboard height: \(keyboardHeight)
viewController Frame: \(view.frame)\n
"""
        )
    }
    
    private func log(_ message: String) {
        Logger.log(title: "HistoryContentInsetManager", message: "\(message)")
    }
}
