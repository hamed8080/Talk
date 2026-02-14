//
//  ThreadViewController.swift
//  Talk
//
//  Created by hamed on 12/30/23.
//

import Foundation
import UIKit
import SwiftUI
import TalkViewModels
import TalkModels
import ChatModels
import TalkUI

@MainActor
final class ThreadViewController: UIViewController {
    var viewModel: ThreadViewModel
    public var tableView: UIHistoryTableView!
    public lazy var sendContainer = ThreadBottomToolbar(viewModel: viewModel)
    lazy var moveToBottom = MoveToBottomButton(viewModel: viewModel)
    public private(set) lazy var unreadMentionsButton = UnreadMenitonsButton(viewModel: viewModel)
    public private(set) lazy var cancelAudioRecordingButton = CancelAudioRecordingButton(viewModel: viewModel)
    public private(set) lazy var topThreadToolbar = TopThreadToolbar(viewModel: viewModel)
    let loadingManager = ThreadLoadingManager()
    var keyboardManager: HistoryKeyboarHeightManager!
    var contentInsetManager: HistoryContentInsetManager!
    var tapGestureManager: HistoryTapGestureManager!
    var delegateObject: ThreadHistoryDelegateImplentation!
    public let emptyThreadView = EmptyThreadView()
    public let vStackOverlayButtons = UIStackView()
    public private(set) lazy var dimView = DimView()
    public var contextMenuContainer: ContextMenuContainerView!
    var isViewControllerVisible: Bool = true
    private var hasEverViewAppeared = false
    
    /// After appending a row while this view is disappeard and return back to this view like adding a participant.
    /// UITableView does not scroll to the row with scrollToRow method if it is not in the current presented view controller.
    var shouldScrollToBottomAtReapperance = false
    
    /// Constraints
    var sendContainerBottomConstraint: NSLayoutConstraint?
    
    init(viewModel: ThreadViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureViews()
        delegateObject = ThreadHistoryDelegateImplentation(controller: self)
        keyboardManager = HistoryKeyboarHeightManager(controller: self)
        contentInsetManager = HistoryContentInsetManager(controller: self)
        tapGestureManager = HistoryTapGestureManager(controller: self)
        tapGestureManager.addTapGesture()
        viewModel.delegate = delegateObject
        viewModel.historyVM.delegate = delegateObject
        delegateObject.showReplyOnOpen()
        delegateObject.startCenterAnimation(true)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        isViewControllerVisible = true
        ThreadViewModel.threadWidth = view.frame.width
        
        if !hasEverViewAppeared {
            hasEverViewAppeared = true
            Task { [weak self] in
                guard let self = self else { return }
                await viewModel.historyVM.start()
            }
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        shouldScrollToBottomAtReapperance = viewModel.scrollVM.isAtBottomOfTheList == true
        isViewControllerVisible = false
        
        /// Clean up navigation if we are moving backward, not forward.
        AppState.shared.objectsContainer.navVM.popOnDisappearIfNeeded(viewController: self, id: viewModel.id)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewModel.historyVM.setThreashold(view.bounds.height * 2.5)
        contextMenuContainer = ContextMenuContainerView(delegate: delegateObject, vc: self)
        
        /// After appending a row while this view is disappeard and return back to this view like adding a participant.
        /// UITableView does not scroll to the row with scrollToRow method if it is not in the current presented view controller.
        if shouldScrollToBottomAtReapperance == true, let indexPath = viewModel.historyVM.lastMessageIndexPath {
            tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
            shouldScrollToBottomAtReapperance = false
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if !keyboardManager.isKeyboardVisible() {
            contentInsetManager.updateContentInset(methodName: "viewDidLayoutSubviews")
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
#if DEBUG
        print("deinit ThreadViewController")
#endif
    }
}

extension ThreadViewController: ConversationNavigationProtocol {
}

// MARK: Configure Views
extension ThreadViewController {
    func configureViews() {
        view.semanticContentAttribute = Language.isRTL ? .forceRightToLeft : .forceLeftToRight
        
        emptyThreadView.attachToParent(parent: view)
        emptyThreadView.isHidden = true
        dimView.viewModel = viewModel
        configureTableView()
        configureOverlayActionButtons()
        configureSendContainer()
        configureTopToolbarVStack()
        loadingManager.configureLoadings(parent: view, tableView: tableView)
        let vStackOverlayButtonsConstraint: NSLayoutConstraint
        if Language.isRTL {
            vStackOverlayButtonsConstraint = vStackOverlayButtons.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: ConstantSizes.vStackButtonsLeadingMargin)
        } else {
            vStackOverlayButtonsConstraint = vStackOverlayButtons.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -ConstantSizes.vStackButtonsLeadingMargin)
        }
        
        sendContainerBottomConstraint = sendContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        sendContainerBottomConstraint?.identifier = "sendContainerBottomConstraintThreadViewController"
        NSLayoutConstraint.activate([
            unreadMentionsButton.widthAnchor.constraint(equalToConstant: 40),
            unreadMentionsButton.heightAnchor.constraint(equalToConstant: 40),
            vStackOverlayButtonsConstraint,
            vStackOverlayButtons.bottomAnchor.constraint(equalTo: sendContainer.topAnchor, constant: -16),
            
            topThreadToolbar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 0),
            topThreadToolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topThreadToolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            sendContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            sendContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            sendContainerBottomConstraint!,
            tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }
    
    private func configureTableView() {
        tableView = UIHistoryTableView(viewModel: viewModel)
        view.addSubview(tableView)
    }
    
    private func configureTopToolbarVStack() {
        view.addSubview(topThreadToolbar)
    }
    
    private func configureSendContainer() {
        sendContainer.translatesAutoresizingMaskIntoConstraints = false
        sendContainer.accessibilityIdentifier = "sendContainerThreadViewController"
        view.addSubview(sendContainer)
        sendContainer.onUpdateHeight = { [weak self] (height: CGFloat) in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                if self.keyboardManager.animatingKeyboard == false {
                    self.delegateObject.moveTolastMessageIfVisible()
                }
            }
        }
    }

    private func configureOverlayActionButtons() {
        vStackOverlayButtons.translatesAutoresizingMaskIntoConstraints = false
        vStackOverlayButtons.axis = .vertical
        vStackOverlayButtons.spacing = 24
        vStackOverlayButtons.alignment = .leading
        vStackOverlayButtons.accessibilityIdentifier = "vStackOverlayButtonsThreadViewController"
        vStackOverlayButtons.addArrangedSubview(moveToBottom)
        unreadMentionsButton.accessibilityIdentifier = "unreadMentionsButtonThreadViewController"
        vStackOverlayButtons.addArrangedSubview(unreadMentionsButton)
        cancelAudioRecordingButton.setIsHidden(true)
        vStackOverlayButtons.addArrangedSubview(cancelAudioRecordingButton)
        view.addSubview(vStackOverlayButtons)
    }
}

extension ThreadViewController {
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        loadingManager.traitCollectionDidChange(previousTraitCollection)
    }
}
