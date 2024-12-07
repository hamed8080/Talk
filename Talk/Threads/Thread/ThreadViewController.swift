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
    var viewModel: ThreadViewModel?
    public var tableView: UIHistoryTableView!
    private let tapGetsure = UITapGestureRecognizer()
    public lazy var sendContainer = ThreadBottomToolbar(viewModel: viewModel)
    private lazy var moveToBottom = MoveToBottomButton(viewModel: viewModel)
    private lazy var unreadMentionsButton = UnreadMenitonsButton(viewModel: viewModel)
    private lazy var cancelAudioRecordingButton = CancelAudioRecordingButton(viewModel: viewModel)
    public private(set) lazy var topThreadToolbar = TopThreadToolbar(viewModel: viewModel)
    private var sendContainerBottomConstraint: NSLayoutConstraint?
    private var keyboardheight: CGFloat = 0
    private var hasExternalKeyboard = false
    private let emptyThreadView = EmptyThreadView()
    private var topLoading = UILoadingView()
    private var centerLoading = UILoadingView()
    private var bottomLoading = UILoadingView()
    private let vStackOverlayButtons = UIStackView()
    private lazy var dimView = DimView()
    public var contextMenuContainer: ContextMenuContainerView!
    private static let loadingViewWidth: CGFloat = 26
    private let topLoadingContainer = UIView(frame: .init(x: 0, y: 0, width: loadingViewWidth, height: loadingViewWidth + 2))
    private let bottomLoadingContainer = UIView(frame: .init(x: 0, y: 0, width: loadingViewWidth, height: loadingViewWidth + 2))
    private var isVisible: Bool = true

    override func viewDidLoad() {
        super.viewDidLoad()
        configureViews()
        registerKeyboard()
        viewModel?.delegate = self
        viewModel?.historyVM.delegate = self
        startCenterAnimation(true)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        isVisible = true
        ThreadViewModel.threadWidth = view.frame.width
        Task {
            await viewModel?.historyVM.start()
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        var hasAnyInstanceInStack = false
        isVisible = false
        navigationController?.viewControllers.forEach({ hostVC in
            hostVC.children.forEach { vc in
                if vc == self {
                    hasAnyInstanceInStack = true
                }
            }
        })
        if !hasAnyInstanceInStack, let viewModel = viewModel {
            AppState.shared.objectsContainer.navVM.cleanOnPop(threadId: viewModel.threadId)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Task { @HistoryActor in
            await viewModel?.historyVM.setThreashold(view.bounds.height * 2.5)
        }
        contextMenuContainer = ContextMenuContainerView(delegate: self)
        tableView.contentInset.top = topThreadToolbar.frame.height
    }

    deinit {
        print("deinit ThreadViewController")
    }
}

// MARK: Configure Views
extension ThreadViewController {
    func configureViews() {
        configureTableView()
        configureOverlayActionButtons()
        configureSendContainer()
        configureTopToolbarVStack()
        configureLoadings()
        let vStackOverlayButtonsConstraint: NSLayoutConstraint
        if Language.isRTL {
            vStackOverlayButtonsConstraint = vStackOverlayButtons.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16)
        } else {
            vStackOverlayButtonsConstraint = vStackOverlayButtons.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        }
        
        sendContainerBottomConstraint = sendContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        sendContainerBottomConstraint?.identifier = "sendContainerBottomConstraintThreadViewController"
        NSLayoutConstraint.activate([
            moveToBottom.widthAnchor.constraint(equalToConstant: 40),
            moveToBottom.heightAnchor.constraint(equalToConstant: 40),
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
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
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
        dimView.translatesAutoresizingMaskIntoConstraints = false
        dimView.accessibilityIdentifier = "dimViewThreadViewController"
        dimView.viewModel = viewModel
        view.addSubview(sendContainer)
        sendContainer.onUpdateHeight = { [weak self] (height: CGFloat) in
            self?.onSendHeightChanged(height)
        }
    }

    private func onSendHeightChanged(_ height: CGFloat) {
        let isButtonsVisible = viewModel?.sendContainerViewModel.showPickerButtons ?? false
        let safeAreaHeight = (isButtonsVisible ? 0 : view.safeAreaInsets.bottom)
        let height = (height - safeAreaHeight) + keyboardheight
        if tableView.contentInset.bottom != height {
            UIView.animate(withDuration: 0.1) { [weak self] in
                guard let self = self else { return }
                tableView.contentInset = .init(top: topThreadToolbar.bounds.height + 4, left: 0, bottom: height, right: 0)
            }
            Task { [weak self] in
                guard let self = self else { return }
                try? await Task.sleep(for: .seconds(0.3))
                await viewModel?.scrollVM.scrollToLastMessageOnlyIfIsAtBottom()
            }
        }
    }

    private func configureOverlayActionButtons() {
        vStackOverlayButtons.translatesAutoresizingMaskIntoConstraints = false
        vStackOverlayButtons.axis = .vertical
        vStackOverlayButtons.spacing = 24
        vStackOverlayButtons.alignment = .leading
        vStackOverlayButtons.accessibilityIdentifier = "vStackOverlayButtonsThreadViewController"
        moveToBottom.accessibilityIdentifier = "moveToBottomThreadViewController"
        vStackOverlayButtons.addArrangedSubview(moveToBottom)
        unreadMentionsButton.accessibilityIdentifier = "unreadMentionsButtonThreadViewController"
        vStackOverlayButtons.addArrangedSubview(unreadMentionsButton)
        cancelAudioRecordingButton.setIsHidden(true)
        vStackOverlayButtons.addArrangedSubview(cancelAudioRecordingButton)
        view.addSubview(vStackOverlayButtons)
    }
    
    private func configureEmptyThreadView() {
        emptyThreadView.alpha = 0.0
        view.addSubview(emptyThreadView)
        emptyThreadView.translatesAutoresizingMaskIntoConstraints = false
        emptyThreadView.accessibilityIdentifier = "emptyThreadViewThreadViewController"
        NSLayoutConstraint.activate([
            emptyThreadView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            emptyThreadView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            emptyThreadView.topAnchor.constraint(equalTo: topThreadToolbar.bottomAnchor),
            emptyThreadView.bottomAnchor.constraint(equalTo: sendContainer.topAnchor),
        ])
    }
    
    private func configureDimView() {
        if dimView.superview == nil {
            dimView.alpha = 0.0
            view.addSubview(dimView)
            view.bringSubviewToFront(dimView)
            dimView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
            dimView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
            dimView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
            dimView.bottomAnchor.constraint(equalTo: sendContainer.topAnchor).isActive = true
        }
    }
    
    private func configureLoadings() {
        topLoading.translatesAutoresizingMaskIntoConstraints = false
        topLoading.accessibilityIdentifier = "topLoadingThreadViewController"
        topLoadingContainer.addSubview(topLoading)
        topLoading.animate(false)
        tableView.tableHeaderView = topLoadingContainer

        centerLoading.translatesAutoresizingMaskIntoConstraints = false
        centerLoading.accessibilityIdentifier = "centerLoadingThreadViewController"

        bottomLoading.translatesAutoresizingMaskIntoConstraints = false
        bottomLoading.accessibilityIdentifier = "bottomLoadingThreadViewController"
        bottomLoadingContainer.addSubview(self.bottomLoading)
        bottomLoading.animate(false)
        tableView.tableFooterView = bottomLoadingContainer

        NSLayoutConstraint.activate([
            topLoading.centerYAnchor.constraint(equalTo: topLoadingContainer.centerYAnchor),
            topLoading.centerXAnchor.constraint(equalTo: topLoadingContainer.centerXAnchor),
            topLoading.widthAnchor.constraint(equalToConstant: ThreadViewController.loadingViewWidth),
            topLoading.heightAnchor.constraint(equalToConstant: ThreadViewController.loadingViewWidth),

            bottomLoading.centerYAnchor.constraint(equalTo: bottomLoadingContainer.centerYAnchor),
            bottomLoading.centerXAnchor.constraint(equalTo: bottomLoadingContainer.centerXAnchor),
            bottomLoading.widthAnchor.constraint(equalToConstant: ThreadViewController.loadingViewWidth),
            bottomLoading.heightAnchor.constraint(equalToConstant: ThreadViewController.loadingViewWidth)
        ])
    }

    private func attachCenterLoading() {
        let width: CGFloat = 28
        view.addSubview(centerLoading)
        centerLoading.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        centerLoading.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        centerLoading.widthAnchor.constraint(equalToConstant: width).isActive = true
        centerLoading.heightAnchor.constraint(equalToConstant: width).isActive = true
    }

    private func showEmptyThread(show: Bool) {
        if show {
            configureEmptyThreadView()
            emptyThreadView.showWithAniamtion(true)
        } else {
            self.emptyThreadView.removeFromSuperViewWithAnimation()
        }
        if show {
            self.unreadMentionsButton.showWithAniamtion(false)
            self.moveToBottom.showWithAniamtion(false)
        }
    }
}

// MARK: ThreadViewDelegate
extension ThreadViewController: ThreadViewDelegate {
    func onScenario() {
        DispatchQueue.main.async { [weak self] in
            self?.moveToBottom.showIfHasAnyUnreadCount()
        }
    }
    
    func onUnreadCountChanged() {
        DispatchQueue.main.async { [weak self] in
            self?.moveToBottom.updateUnreadCount()
        }
    }

    func onChangeUnreadMentions() {
        DispatchQueue.main.async { [weak self] in
            self?.unreadMentionsButton.onChangeUnreadMentions()
        }
    }

    func setSelection(_ value: Bool) {
        tapGetsure.isEnabled = !value
        viewModel?.selectedMessagesViewModel.setInSelectionMode(value)
        tableView.allowsMultipleSelection = value
        tableView.visibleCells.compactMap{$0 as? MessageBaseCell}.forEach { cell in
            cell.setInSelectionMode(value)
        }

        // Assure that the previous item is in select mode or not
        if let cell = prevouisVisibleIndexPath() {
            cell.setInSelectionMode(value)
        }

        // Assure that the next item is in select mode or not
        if let cell = nextVisibleIndexPath() {
            cell.setInSelectionMode(value)
        }

        showSelectionBar(value)
        // We need a delay to show selection view to calculate height of sendContainer then update to the last Message if it is visible
        Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { [weak self] _ in
            Task { [weak self] in
                await self?.moveTolastMessageIfVisible()
            }
        }

        if !value {
            tableView.resetSelection()
        }
    }

    func updateSelectionView() {
        sendContainer.updateSelectionBar()
    }

    func lastMessageAppeared(_ appeared: Bool) {
        self.moveToBottom.setVisibility(visible: !appeared)
        if self.viewModel?.scrollVM.isAtBottomOfTheList == true {
            self.tableView.tableFooterView = nil
        } else {
            self.tableView.tableFooterView = self.bottomLoadingContainer
        }
    }

    func startTopAnimation(_ animate: Bool) {
        DispatchQueue.main.async {
            self.tableView.tableHeaderView?.isHidden = !animate
            UIView.animate(withDuration: 0.25) {
                self.tableView.tableHeaderView?.layoutIfNeeded()
            }
            self.topLoading.animate(animate)
        }
    }

    func startCenterAnimation(_ animate: Bool) {
        DispatchQueue.main.async {
            if animate {
                self.attachCenterLoading()
                self.centerLoading.animate(animate)
            } else {
                self.centerLoading.removeFromSuperViewWithAnimation()
            }
        }
    }

    func startBottomAnimation(_ animate: Bool) {
        DispatchQueue.main.async {
            self.tableView.tableFooterView?.isHidden = !animate
            UIView.animate(withDuration: 0.25) {
                self.tableView.tableFooterView?.layoutIfNeeded()
            }
            self.bottomLoading.animate(animate)
        }
    }

    func openShareFiles(urls: [URL], title: String?, sourceView: UIView?) {
        guard let first = urls.first else { return }
        let vc = UIActivityViewController(activityItems: [LinkMetaDataManager(url: first, title: title)], applicationActivities: nil)
        vc.popoverPresentationController?.sourceView = sourceView
        present(vc, animated: true)
    }

    func onMentionListUpdated() {
        sendContainer.updateMentionList()
        tapGetsure.isEnabled = viewModel?.mentionListPickerViewModel.mentionList.count == 0
    }

    func updateAvatar(image: UIImage, participantId: Int) {
        tableView.visibleCells
            .compactMap({$0 as? PartnerMessageCell})
            .filter{$0.viewModel?.message.participant?.id == participantId}
            .forEach { cell in
                cell.setImage(image)
            }
    }

    func edited(_ indexPath: IndexPath) {
        if let cell = baseCell(indexPath) {
            tableView.performBatchUpdates {
                cell.edited()
            }
        }
    }

    func pinChanged(_ indexPath: IndexPath) {
        if let cell = baseCell(indexPath) {
            cell.pinChanged()
        }
    }

    func sent(_ indexPath: IndexPath) {
        if let cell = baseCell(indexPath) {
            cell.sent()
        }
    }

    func delivered(_ indexPath: IndexPath) {
        if let cell = baseCell(indexPath) {
            cell.delivered()
        }
    }

    func seen(_ indexPath: IndexPath) {
        if let cell = baseCell(indexPath) {
            cell.seen()
        }
    }

    public func updateTitleTo(_ title: String?) {
        topThreadToolbar.updateTitleTo(title)
    }

    public func updateSubtitleTo(_ subtitle: String?) {
        topThreadToolbar.updateSubtitleTo(subtitle)
    }

    public func updateImageTo(_ image: UIImage?) {
        topThreadToolbar.updateImageTo(image)
    }

    public func refetchImageOnUpdateInfo() {
        topThreadToolbar.refetchImageOnUpdateInfo()
    }

    func setHighlightRowAt(_ indexPath: IndexPath, highlight: Bool) {
        if let cell = baseCell(indexPath) {
            cell.setHighlight()
        }
    }

    func showContextMenu(_ indexPath: IndexPath?, contentView: UIView) {
        contextMenuContainer.setContentView(contentView, indexPath: indexPath)
        contextMenuContainer.show()
    }

    func dismissContextMenu(indexPath: IndexPath?) {
        contextMenuContainer.hide()
        if let indexPath = indexPath, let cell = tableView.cellForRow(at: indexPath) as? MessageBaseCell {
            cell.messageContainer.resetOnDismiss()
        }
    }

    func onUpdatePinMessage() {
        topThreadToolbar.updatePinMessage()
    }

    func onConversationClosed() {
        sendContainer.onConversationClosed()
    }
}

extension ThreadViewController: BottomToolbarDelegate {
    func showMainButtons(_ show: Bool) {
        sendContainer.showMainButtons(show)
    }

    func showSelectionBar(_ show: Bool) {
        sendContainer.showSelectionBar(show)
        showMainButtons(!show)
    }

    func showPickerButtons(_ show: Bool) {
        viewModel?.sendContainerViewModel.showPickerButtons(show)
        sendContainer.showPickerButtons(show)
        configureDimView()
        dimView.show(show)
    }
    
    func showSendButton(_ show: Bool) {
        sendContainer.showSendButton(show)
    }

    func showMicButton(_ show: Bool) {
        sendContainer.showMicButton(show)
    }

    func onItemsPicked() {
        showSendButton(true)
        showMicButton(false)
    }

    func showRecording(_ show: Bool) {
        sendContainer.openRecording(show)
        cancelAudioRecordingButton.setIsHidden(!show)
    }

    func openEditMode(_ message: (any HistoryMessageProtocol)?) {
        sendContainer.openEditMode(message)
        // We only check if we select a message to edit. For closing and sending message where message is nil we leave the focus remain on the textfield to send further messages.
        if message != nil {
            focusOnTextView(focus: true)
        }
    }

    func openReplyMode(_ message: (any HistoryMessageProtocol)?) {
        // We only check if we select a message to reply. For closing and sending message where message is nil we leave the focus remain on the textfield to send further messages.
        if message != nil {
            focusOnTextView(focus: true)
        }
        viewModel?.replyMessage = message as? Message
        sendContainer.openReplyMode(message)
        viewModel?.scrollVM.disableExcessiveLoading()
        scrollTo(uniqueId: message?.uniqueId ?? "", position: hasExternalKeyboard ? .none : .middle)
    }

    func focusOnTextView(focus: Bool) {
        sendContainer.focusOnTextView(focus: focus)
    }

    func showForwardPlaceholder(show: Bool) {
        sendContainer.showForwardPlaceholder(show: show)
    }

    func showReplyPrivatelyPlaceholder(show: Bool) {
        sendContainer.showReplyPrivatelyPlaceholder(show: show)
    }

    func muteChanged() {
        sendContainer.muteChanged()
    }
}

// MARK: Sheets Delegate
extension ThreadViewController {
    func openForwardPicker() {
        let view = SelectConversationOrContactList { [weak self] (conversation, contact) in
            self?.viewModel?.sendMessageViewModel.openDestinationConversationToForward(conversation, contact)
        }
            .environmentObject(AppState.shared.objectsContainer.threadsVM)
            .contextMenuContainer()
//            .environmentObject(AppState.shared.objectsContainer.contactsVM)
            .onDisappear {
                //closeSheet()
            }
        let hostVC = UIHostingController(rootView: view)
        hostVC.modalPresentationStyle = .formSheet
        present(hostVC, animated: true)
    }

    func openMoveToDatePicker() {
        AppState.shared.objectsContainer.appOverlayVM.dialogView = AnyView(DatePickerDialogWrapper(viewModel: viewModel))
    }
}

// MARK: Scrolling to
extension ThreadViewController: HistoryScrollDelegate {
    func emptyStateChanged(isEmpty: Bool) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            showEmptyThread(show: isEmpty)
        }
    }

    func reload() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            tableView.reloadData()
        }
    }

    func scrollTo(index: IndexPath, position: UITableView.ScrollPosition, animate: Bool = true) {
        DispatchQueue.main.async { [weak self] in
            self?.tableView.scrollToRow(at: index, at: position, animated: animate)
        }
    }

    func scrollTo(uniqueId: String, position: UITableView.ScrollPosition, animate: Bool = true) {
        if let indexPath = viewModel?.historyVM.mSections.indicesByMessageUniqueId(uniqueId) {
            scrollTo(index: indexPath, position: position, animate: animate)
        }
    }

    func reload(at: IndexPath) {
        DispatchQueue.main.async { [weak self] in
            self?.tableView.reloadRows(at: [at], with: .fade)
        }
    }

    func moveRow(at: IndexPath, to: IndexPath) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            tableView.moveRow(at: at, to: to)
        }
    }

    func reloadData(at: IndexPath) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if let cell = tableView.cellForRow(at: at) as? MessageBaseCell, let vm = viewModel?.historyVM.mSections.viewModelWith(at) {
                cell.setValues(viewModel: vm)
            }
        }
    }

    private func moveTolastMessageIfVisible() {
        if viewModel?.scrollVM.isAtBottomOfTheList == true, let indexPath = viewModel?.historyVM.mSections.viewModelAndIndexPath(for: viewModel?.thread.lastMessageVO?.id)?.indexPath {
            scrollTo(index: indexPath, position: .bottom)
        }
    }

    func uploadCompleted(at: IndexPath, viewModel: MessageRowViewModel) {
        DispatchQueue.main.async { [weak self] in
            guard let cell = self?.tableView.cellForRow(at: at) as? MessageBaseCell else { return }
            cell.uploadCompleted(viewModel: viewModel)
        }
    }

    func downloadCompleted(at: IndexPath, viewModel: MessageRowViewModel) {
        DispatchQueue.main.async { [weak self] in
            guard let cell = self?.tableView.cellForRow(at: at) as? MessageBaseCell else { return }
            cell.downloadCompleted(viewModel: viewModel)
        }
    }

    func updateProgress(at: IndexPath, viewModel: MessageRowViewModel) {
        DispatchQueue.main.async { [weak self] in
            guard let cell = self?.tableView.cellForRow(at: at) as? MessageBaseCell else { return }
            cell.updateProgress(viewModel: viewModel)
        }
    }

    func updateThumbnail(at: IndexPath, viewModel: MessageRowViewModel) {
        DispatchQueue.main.async { [weak self] in
            guard let cell = self?.tableView.cellForRow(at: at) as? MessageBaseCell else { return }
            cell.updateThumbnail(viewModel: viewModel)
        }
    }

    func updateReplyImageThumbnail(at: IndexPath, viewModel: MessageRowViewModel) {
        DispatchQueue.main.async { [weak self] in
            guard let cell = self?.tableView.cellForRow(at: at) as? MessageBaseCell else { return }
            cell.updateReplyImageThumbnail(viewModel: viewModel)
        }
    }

    func inserted(at: IndexPath) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            tableView.beginUpdates()
            // Insert a new section if we have a message in a new day.
            let beforeNumberOfSections = tableView.numberOfSections
            if beforeNumberOfSections < at.section + 1 { // +1 for make it count instead of index
                tableView.insertSections(IndexSet(beforeNumberOfSections..<at.section + 1), with: .none)
            }
            tableView.insertRows(at: [at], with: .fade)
            tableView.endUpdates()
        }
    }

    func inserted(_ sections: IndexSet, _ rows: [IndexPath], _ animate :UITableView.RowAnimation = .top, _ scrollTo: IndexPath?) {
        DispatchQueue.main.async { [weak self] in
            self?.inserted(sections: sections, rows: rows, animate: animate, scrollTo: scrollTo)
        }
    }

    private func inserted(sections: IndexSet, rows: [IndexPath], animate :UITableView.RowAnimation = .top, scrollTo: IndexPath?) {

        // Save the current content offset and content height
//        let beforeOffsetY = tableView.contentOffset.y
//        let beforeContentHeight = tableView.contentSize.height
//        print("before offset y is: \(beforeOffsetY)")
//
//        // Begin table view updates
//        tableView.beginUpdates()
//
//        // Insert the sections and rows without animation
//        tableView.insertSections(sections, with: .middle)
//        tableView.insertRows(at: rows, with: .middle)
//
//        // Calculate the new content size and offset
//        let afterContentHeight = tableView.contentSize.height
//        let offsetChange = afterContentHeight - beforeContentHeight
//
//        // Update the content offset to keep the visible content stationary
//        let newOffsetY = beforeOffsetY + offsetChange
//        print("new offset y is: \(newOffsetY)")
//        tableView.contentOffset.y = newOffsetY
//        tableView.setContentOffset(.init(x: 0, y: newOffsetY), animated: true)

        // End table view updates
//        tableView.endUpdates()
//
//        if let scrollTo = scrollTo {
//            self.tableView.scrollToRow(at: scrollTo, at: .top, animated: false)
//        }

        if let scrollTo = scrollTo {
            UIView.performWithoutAnimation {
                tableView.performBatchUpdates {
                    // Insert the sections and rows without animation
                    tableView.insertSections(sections, with: animate)
                    tableView.insertRows(at: rows, with: animate)
                } completion: { completed in
                    DispatchQueue.main.async {
                        self.tableView.scrollToRow(at: scrollTo, at: .top, animated: false)
                    }
                }
            }
        } else {
            tableView.performBatchUpdates {
                // Insert the sections and rows without animation
                tableView.insertSections(sections, with: animate)
                tableView.insertRows(at: rows, with: animate)
            }
        }
    }

    func inserted(at: [IndexPath]) {
        DispatchQueue.main.async { [weak self] in
            self?.tableView.beginUpdates()
            self?.tableView.insertRows(at: at, with: .fade)
            self?.tableView.endUpdates()
        }
    }

    func removed(at: IndexPath) {
        guard let viewModel = viewModel else { return }
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            tableView.beginUpdates()
            if tableView.numberOfSections > viewModel.historyVM.mSections.count {
                tableView.deleteSections(IndexSet(viewModel.historyVM.mSections.count..<tableView.numberOfSections), with: .fade)
            }
            tableView.deleteRows(at: [at], with: .fade)
            tableView.endUpdates()
        }
    }

    func removed(at: [IndexPath]) {
        guard let viewModel = viewModel else { return }
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            tableView.beginUpdates()
            if tableView.numberOfSections > viewModel.historyVM.mSections.count {
                tableView.deleteSections(IndexSet(viewModel.historyVM.mSections.count..<tableView.numberOfSections), with: .fade)
            }
            tableView.deleteRows(at: at, with: .fade)
            tableView.endUpdates()
        }
    }
    
    func performBatchUpdateForReactions(_ indexPaths: [IndexPath]) {
        viewModel?.historyVM.isUpdating = true
        tableView.performBatchUpdates {
            for indexPath in indexPaths {
                let cell = tableView.cellForRow(at: indexPath) as? MessageBaseCell
                if let cell = cell, let viewModel = viewModel?.historyVM.mSections.viewModelWith(indexPath) {
                    cell.reactionsUpdated(viewModel: viewModel)
                }
            }
        } completion: { [weak self] completed in
            self?.viewModel?.historyVM.isUpdating = false
        }
    }
}

struct UIKitThreadViewWrapper: UIViewControllerRepresentable {
    let threadVM: ThreadViewModel

    func makeUIViewController(context: Context) -> some UIViewController {
        let vc = ThreadViewController()
        vc.viewModel = threadVM
        return vc
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {

    }
}

// MARK: Keyboard apperance
extension ThreadViewController {
    private func registerKeyboard() {
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { [weak self] notif in
            let rect = notif.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
            Task { [weak self] in
                await self?.onShowKeyboard(rect)
            }
        }

        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { [weak self] _ in
            Task { [weak self] in
                await self?.onHideKeyorad()
            }
        }
        tapGetsure.addTarget(self, action: #selector(hideKeyboard))
        tapGetsure.isEnabled = true
        view.addGestureRecognizer(tapGetsure)
    }
    
    private func onShowKeyboard(_ rect: CGRect?) {
        if isVisible == false { return }
        if let rect = rect {
            if rect.size.height <= 69 {
                hasExternalKeyboard = true
            } else {
                hasExternalKeyboard = false
            }

            UIView.animate(withDuration: 0.2) {
                self.sendContainerBottomConstraint?.constant = -rect.height
                self.keyboardheight = rect.height
                self.view.layoutIfNeeded()
            } completion: { completed in
                if completed {
                    self.moveTolastMessageIfVisible()
                }
            }
        }
    }
    
    private func onHideKeyorad() {
        if isVisible == false { return }
        sendContainerBottomConstraint?.constant = 0
        keyboardheight = 0
        hasExternalKeyboard = false
        UIView.animate(withDuration: 0.2) {
            self.view.layoutIfNeeded()
        }
    }

    @objc private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: Table view cell helpers
extension ThreadViewController {
    private func baseCell(_ indexPath: IndexPath) -> MessageBaseCell? {
        if let cell = tableView.cellForRow(at: indexPath) as? MessageBaseCell {
            return cell
        }
        return nil
    }

    private func isVisible(_ indexPath: IndexPath) -> Bool {
        tableView.indexPathsForVisibleRows?.contains(where: {$0 == indexPath}) == true
    }

    private func prevouisVisibleIndexPath() -> MessageBaseCell? {
        if let firstVisible = tableView.indexPathsForVisibleRows?.first, let previousIndexPath = viewModel?.historyVM.mSections.previousIndexPath(firstVisible) {
            let cell = tableView.cellForRow(at: previousIndexPath) as? MessageBaseCell
            return cell
        }
        return nil
    }

    private func nextVisibleIndexPath() -> MessageBaseCell? {
        if let lastVisible = tableView.indexPathsForVisibleRows?.last, let nextIndexPath = viewModel?.historyVM.mSections.nextIndexPath(lastVisible) {
            let cell = tableView.cellForRow(at: nextIndexPath) as? MessageBaseCell
            return cell
        }
        return nil
    }
}
