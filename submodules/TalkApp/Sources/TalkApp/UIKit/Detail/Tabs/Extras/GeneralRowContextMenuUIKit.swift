//
//  GeneralRowContextMenuUIKit.swift
//  TalkApp
//
//  Created by Hamed Hosseini on 12/24/25.
//

import Foundation
import UIKit
import SwiftUI
import TalkViewModels

class GeneralRowContextMenuUIKit: UIView {
    private let model: TabRowModel
    private weak var viewModel: ThreadDetailViewModel?
    private weak var parentVC: UIViewController?
    private let container: ContextMenuContainerView?
    private let cell: UIView
    private let showFileShareSheet: Bool
    
    public init(model: TabRowModel,
                cell: UIView,
                container: ContextMenuContainerView?,
                showFileShareSheet: Bool,
                parentVC: UIViewController,
                viewModel: ThreadDetailViewModel?) {
        self.model = model
        self.cell = cell
        self.viewModel = viewModel
        self.container = container
        self.parentVC = parentVC
        self.showFileShareSheet = showFileShareSheet
        super.init(frame: .zero)
        configureView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureView() {
        semanticContentAttribute = Language.isRTL ? .forceRightToLeft : .forceLeftToRight
        
        let menu = configureMenu()
        menu.contexMenuContainer = container
        menu.translatesAutoresizingMaskIntoConstraints = false
        addSubview(menu)
      
        addSubview(cell)
        
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: container?.frame.height ?? 0),
    
            menu.topAnchor.constraint(equalTo: cell.bottomAnchor, constant: 8),
            menu.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 0),
            menu.widthAnchor.constraint(equalToConstant: 256),
        ])
    }
    
    public func attachCellToParent() {
        NSLayoutConstraint.activate([
            cell.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            cell.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -48),
            cell.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            cell.heightAnchor.constraint(equalToConstant: 82)
        ])
    }
    
    public func centerCellInParent() {
        NSLayoutConstraint.activate([
            cell.centerXAnchor.constraint(equalTo: centerXAnchor, constant: 0),
            cell.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 0),
        ])
    }
    
    private func configureMenu() -> CustomMenu {
        let menu = CustomMenu()
        
        let jumpToMessage = jumpToMessageAction()
        menu.addItem(jumpToMessage)
       
        if showFileShareSheet {
            let shareFile = shareFileAction()
            menu.addItem(shareFile)
        }
        
        return menu
    }
    
    @MainActor
    func jumpToMessageAction() -> ActionMenuItem {
        let title = "General.showMessage".bundleLocalized()
        let image = "message.fill"
        let historyVM = viewModel?.threadVM?.historyVM
        
        let model = ActionItemModel(title: title, image: image)
        let jumpToMessage = ActionMenuItem(model: model) { [weak self] in
            guard let self = self else { return }
            Task {
                await historyVM?.moveToTime(self.model.message.time ?? 0, self.model.message.id ?? -1, highlight: true)
            }
            let threadId = viewModel?.threadVM?.id ?? -1
            AppState.shared.objectsContainer.navVM.removeDetail(id: threadId)
            container?.hide()
        }
    
        return jumpToMessage
    }
    
    @MainActor
    func shareFileAction() -> ActionMenuItem {
        let title = "Messages.ActionMenu.share".bundleLocalized()
        let image = "square.and.arrow.up"
        let historyVM = viewModel?.threadVM?.historyVM
        
        let model = ActionItemModel(title: title, image: image)
        let share = ActionMenuItem(model: model) { [weak self] in
            guard let self = self else { return }
            Task { await self.model.presentShareSheet(parentVC: parentVC) }
        }
    
        return share
    }
}

extension GeneralRowContextMenuUIKit {
    static func showGeneralContextMenuRow(newCell: UITableViewCell,
                                          tb: UITableView,
                                          model: TabRowModel,
                                          detailVM: ThreadDetailViewModel?,
                                          contextMenuContainer: ContextMenuContainerView?,
                                          showFileShareSheet: Bool = true,
                                          parentVC: UIViewController,
                                          indexPath: IndexPath
                                          
    ) {
        
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred(intensity: 1.0)
        
        newCell.contentView.layer.cornerRadius = 16
        newCell.contentView.layer.masksToBounds = true
        newCell.contentView.backgroundColor = Color.App.bgPrimaryUIColor
        newCell.translatesAutoresizingMaskIntoConstraints = false
        newCell.layer.cornerRadius = 16
        
        let contentView = GeneralRowContextMenuUIKit(model: model,
                                                     cell: newCell,
                                                     container: contextMenuContainer,
                                                     showFileShareSheet: showFileShareSheet,
                                                     parentVC: parentVC,
                                                     viewModel: detailVM)
        contentView.attachCellToParent()
        
        contextMenuContainer?.setContentView(contentView, indexPath: indexPath)
        contextMenuContainer?.show()
    }
}


extension GeneralRowContextMenuUIKit {
    static func showGeneralContextMenuRow(view: UIView,
                                          model: TabRowModel,
                                          detailVM: ThreadDetailViewModel?,
                                          contextMenuContainer: ContextMenuContainerView?,
                                          showFileShareSheet: Bool = true,
                                          parentVC: UIViewController,
                                          indexPath: IndexPath
                                          
    ) {
        
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred(intensity: 1.0)
        
        let contentView = GeneralRowContextMenuUIKit(model: model,
                                                     cell: view,
                                                     container: contextMenuContainer,
                                                     showFileShareSheet: showFileShareSheet,
                                                     parentVC: parentVC,
                                                     viewModel: detailVM)
        contentView.centerCellInParent()
        contextMenuContainer?.setContentView(contentView, indexPath: indexPath)
        contextMenuContainer?.show()
    }
}
