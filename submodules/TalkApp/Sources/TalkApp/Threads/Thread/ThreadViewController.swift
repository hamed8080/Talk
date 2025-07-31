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
    private let loadingManager = ThreadLoadingManager()
    private var sendContainerBottomConstraint: NSLayoutConstraint?
    private var keyboardheight: CGFloat = 0
    private var hasExternalKeyboard = false
    private let emptyThreadView = EmptyThreadView()
    private let vStackOverlayButtons = UIStackView()
    private lazy var dimView = DimView()
    public var contextMenuContainer: ContextMenuContainerView!
    private var isViewControllerVisible: Bool = true
    private var sections: ContiguousArray<MessageSection> { viewModel?.historyVM.sections ?? [] }
    private var animatingKeyboard = false

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
        isViewControllerVisible = true
        ThreadViewModel.threadWidth = view.frame.width
        Task {
            await viewModel?.historyVM.start()
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        var hasAnyInstanceInStack = false
        isViewControllerVisible = false
        navigationController?.viewControllers.forEach({ hostVC in
            hostVC.children.forEach { vc in
                if vc == self {
                    hasAnyInstanceInStack = true
                }
            }
        })
        if !hasAnyInstanceInStack, let viewModel = viewModel {
            AppState.shared.objectsContainer.navVM.cleanOnPop(threadId: viewModel.threadId)
            viewModel.threadsViewModel?.setSelected(for: viewModel.threadId, selected: false, isArchive: viewModel.thread.isArchive == true)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewModel?.historyVM.setThreashold(view.bounds.height * 2.5)
        contextMenuContainer = ContextMenuContainerView(delegate: self)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if keyboardheight == 0 {
            let height = sendContainer.bounds.height - sendContainer.safeAreaInsets.bottom
            tableView.contentInset = .init(top: topThreadToolbar.bounds.height + 4, left: 0, bottom: height, right: 0)
            tableView.scrollIndicatorInsets = .init(top: topThreadToolbar.bounds.height + 4, left: 0, bottom: height, right: 0)
        }
    }

#if DEBUG
    deinit {
        print("deinit ThreadViewController")
    }
#endif
}

// MARK: Configure Views
extension ThreadViewController {
    func configureViews() {
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
            vStackOverlayButtonsConstraint = vStackOverlayButtons.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16)
        } else {
            vStackOverlayButtonsConstraint = vStackOverlayButtons.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
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
        view.addSubview(sendContainer)
        sendContainer.onUpdateHeight = { [weak self] (height: CGFloat) in
            self?.onSendHeightChanged(height)
            if self?.animatingKeyboard == false {
                self?.moveTolastMessageIfVisible()
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

    private func showEmptyThread(show: Bool) {
        /// We only need to set to false for the first time, after that it will be removed
        /// or add to view.
        if show {
            emptyThreadView.isHidden = false
        }
        emptyThreadView.show(show, parent: view)
        if show {
            self.unreadMentionsButton.showWithAniamtion(false)
            self.moveToBottom.show(false)
            view.bringSubviewToFront(vStackOverlayButtons)
            view.bringSubviewToFront(sendContainer)
        }
    }
}

// MARK: ThreadViewDelegate
extension ThreadViewController: ThreadViewDelegate {
    
    func showMoveToBottom(show: Bool) {
        moveToBottom.show(show)
    }
    
    func isMoveToBottomOnScreen() -> Bool {
        return !moveToBottom.isHidden
    }
    
    func onUnreadCountChanged() {
#if DEBUG
        print("onUnreadCountChanged \(viewModel?.thread.unreadCount ?? 0)")
#endif
        moveToBottom.updateUnreadCount()
    }

    func onChangeUnreadMentions() {
        unreadMentionsButton.onChangeUnreadMentions()
    }
    
    func setTableRowSelected(_ indexPath: IndexPath) {
        tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
    }

    func setSelection(_ value: Bool) {
        tapGetsure.isEnabled = !value
        viewModel?.selectedMessagesViewModel.setInSelectionMode(value)
        tableView.allowsMultipleSelection = value
        tableView.visibleCells.compactMap{$0 as? MessageBaseCell}.forEach { cell in
            cell.setInSelectionMode(value)
        }
        
        // Assure that the previous resuable rows items are in select mode or not
        for cell in tableView.prevouisVisibleIndexPath() {
            cell.setInSelectionMode(value)
        }

        // Assure that the next resuable rows items are in select mode or not
        for cell in tableView.nextVisibleIndexPath() {
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
        self.moveToBottom.show(!appeared)
        if self.viewModel?.scrollVM.isAtBottomOfTheList == true {
            self.tableView.tableFooterView = nil
        }
    }
    
    func startTopAnimation(_ animate: Bool) {
        self.tableView.tableHeaderView?.isHidden = !animate
        UIView.animate(withDuration: 0.25) {
            self.tableView.tableHeaderView?.layoutIfNeeded()
        }
        self.loadingManager.startTopAnimation(animate)
    }
    
    func startCenterAnimation(_ animate: Bool) {
        self.loadingManager.startCenterAnimation(animate)
    }

    func startBottomAnimation(_ animate: Bool) {
        self.tableView.tableFooterView = animate ? self.loadingManager.getBottomLoadingContainer() : nil
        self.tableView.tableFooterView?.isHidden = !animate
        UIView.animate(withDuration: 0.25) {
            self.tableView.tableFooterView?.layoutIfNeeded()
        }
        self.loadingManager.startBottomAnimation(animate)
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
        if let cell = tableView.baseCell(indexPath) {
            tableView.performBatchUpdates {
                cell.edited()
            }
        }
    }

    func pinChanged(_ indexPath: IndexPath) {
        if let cell = tableView.baseCell(indexPath) {
            cell.pinChanged()
        }
    }

    func sent(_ indexPath: IndexPath) {
        if let cell = tableView.baseCell(indexPath) {
            cell.sent()
        }
    }

    func delivered(_ indexPath: IndexPath) {
        if let cell = tableView.baseCell(indexPath) {
            cell.delivered()
        }
    }

    func seen(_ indexPath: IndexPath) {
        if let cell = tableView.baseCell(indexPath) {
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
        if let cell = tableView.baseCell(indexPath) {
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
    
    func visibleIndexPaths() -> [IndexPath] {
        tableView.indexPathsForVisibleRows ?? []
    }
    
    func lastMessageIndexPathIfVisible() -> IndexPath? {
        guard viewModel?.scrollVM.isAtBottomOfTheList == true else { return nil }
        return tableView.indexPathsForVisibleRows?.last
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
        sendContainer.showPickerButtons(show)
        dimView.attachToParent(parent: view, bottomYAxis: sendContainer.topAnchor)
        dimView.show(show)
    }

    func showRecording(_ show: Bool) {
        sendContainer.openRecording(show)
        cancelAudioRecordingButton.setIsHidden(!show)
    }

    func openEditMode(_ message: HistoryMessageType?) {
        // We only check if we select a message to edit. For closing and sending message where message is nil we leave the focus remain on the textfield to send further messages.
        if message != nil {
            focusOnTextView(focus: true)
            openReplyMode(nil)
        }
    }

    func openReplyMode(_ message: HistoryMessageType?) {
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
        let selectVM = viewModel?.selectedMessagesViewModel
        let messages = selectVM?.getSelectedMessages().compactMap{$0.message as? Message} ?? []
        
        let view = SelectConversationOrContactList { [weak self] (conversation, contact) in
            self?.viewModel?.sendMessageViewModel.openDestinationConversationToForward(conversation, contact, messages)
        }
            .environmentObject(AppState.shared.objectsContainer.threadsVM)
            .contextMenuContainer()
        
        let hostVC = UIHostingController(rootView: view)
        hostVC.modalPresentationStyle = .formSheet
        present(hostVC, animated: true)
    }

    func openMoveToDatePicker() {
        AppState.shared.objectsContainer.appOverlayVM.dialogView = AnyView(
            DatePickerWrapper(hideControls: false) { [weak self] date in
                self?.viewModel?.historyVM.moveToTimeByDate(time: UInt(date.millisecondsSince1970))
                AppState.shared.objectsContainer.appOverlayVM.dialogView = nil
            }
            .frame(width: AppState.shared.windowMode.isInSlimMode ? 310 : 320, height: 420)
        )
    }
}

// MARK: Scrolling to
extension ThreadViewController: HistoryScrollDelegate {
    func emptyStateChanged(isEmpty: Bool) {
        showEmptyThread(show: isEmpty)
    }
    
    func reload() {
        tableView.reloadData()
    }
    
    func scrollTo(index: IndexPath, position: UITableView.ScrollPosition, animate: Bool = true) {
        if tableView.numberOfSections == 0 { return }
        if tableView.numberOfRows(inSection: index.section) < index.row + 1 { return }
        tableView.scrollToRow(at: index, at: position, animated: animate)
    }
    
    func scrollTo(uniqueId: String, position: UITableView.ScrollPosition, animate: Bool = true) {
        if let indexPath = sections.indicesByMessageUniqueId(uniqueId) {
            scrollTo(index: indexPath, position: position, animate: animate)
        }
    }
    
    func reload(at: IndexPath) {
        tableView.reloadRows(at: [at], with: .fade)
    }
    
    func moveRow(at: IndexPath, to: IndexPath) {
        tableView.moveRow(at: at, to: to)
    }
    
    func reloadData(at: IndexPath) {
        if let cell = tableView.cellForRow(at: at) as? MessageBaseCell, let vm = sections.viewModelWith(at) {
            cell.setValues(viewModel: vm)
        }
    }
    
    private func moveTolastMessageIfVisible() {
        if viewModel?.scrollVM.isAtBottomOfTheList == true, let indexPath = sections.viewModelAndIndexPath(for: viewModel?.thread.lastMessageVO?.id)?.indexPath {
            scrollTo(index: indexPath, position: .bottom)
        }
    }
    
    func uploadCompleted(at: IndexPath, viewModel: MessageRowViewModel) {
        guard let cell = tableView.cellForRow(at: at) as? MessageBaseCell else { return }
        cell.uploadCompleted(viewModel: viewModel)
    }
    
    func downloadCompleted(at: IndexPath, viewModel: MessageRowViewModel) {
        guard let cell = tableView.cellForRow(at: at) as? MessageBaseCell else { return }
        cell.downloadCompleted(viewModel: viewModel)
    }
    
    func updateProgress(at: IndexPath, viewModel: MessageRowViewModel) {
        guard let cell = tableView.cellForRow(at: at) as? MessageBaseCell else { return }
        cell.updateProgress(viewModel: viewModel)
    }
    
    func updateReplyImageThumbnail(at: IndexPath, viewModel: MessageRowViewModel) {
        guard let cell = tableView.cellForRow(at: at) as? MessageBaseCell else { return }
        cell.updateReplyImageThumbnail(viewModel: viewModel)
    }
    
    func inserted(at: IndexPath) {
        log("inserted at indexPath: \(at)")
        log("TableView state: \(tableView.numberOfSections), data source state: \(viewModel?.historyVM.sections.count)")
        tableView.beginUpdates()
        
        // Insert a new section if we have a message in a new day.
        let beforeNumberOfSections = tableView.numberOfSections
        if beforeNumberOfSections < at.section + 1 { // +1 for make it count instead of index
            tableView.insertSections(IndexSet(beforeNumberOfSections..<at.section + 1), with: .none)
        }
        tableView.insertRows(at: [at], with: .fade)
        tableView.endUpdates()
    }
    
    func inserted(_ sections: IndexSet, _ rows: [IndexPath], _ animate: UITableView.RowAnimation = .top, _ scrollTo: IndexPath?) {
        if let scrollTo = scrollTo {
            insertedWithoutAnimation(sections: sections, rows: rows, scrollTo: scrollTo)
        } else {
            insertedWithAnimation(sections: sections, rows: rows)
        }
    }
    
    func inserted(_ sections: IndexSet, _ rows: [IndexPath], _ scrollToIndexPath: IndexPath, _ at: UITableView.ScrollPosition = .none) {
        UIView.performWithoutAnimation {
            tableView.beginUpdates()
            
            if !sections.isEmpty {
                self.tableView.insertSections(sections, with: .none)
            }
            if !rows.isEmpty {
                self.tableView.insertRows(at: rows, with: .none)
            }
            tableView.endUpdates()
            
            tableView.scrollToRow(at: scrollToIndexPath, at: at, animated: false)
        }
    }
    
    func insertedWithoutAnimation(sections: IndexSet, rows: [IndexPath], scrollTo: IndexPath) {
        log("inserted and scroll to")
        log("insertingSections without animation: \(sections), insertingRows: \(rows)")
        log("TableView state without animation: \(tableView.numberOfSections), data source state: \(viewModel?.historyVM.sections.count)")
        
        /// We use setContentOffset instead of scrollTo,
        /// it will move without jumping sections and it needs estimated height to be close and calculated
        /// in advance, in order to append at top smoothly.
        
        // 1. Capture contentOffset and contentSize before insert
        let previousOffset = tableView.contentOffset
        let previousContentHeight = tableView.contentSize.height
        UIView.performWithoutAnimation {
            tableView.beginUpdates()
             
            if !sections.isEmpty {
                self.tableView.insertSections(sections, with: .none)
            }
            if !rows.isEmpty {
                self.tableView.insertRows(at: rows, with: .none)
            }
            tableView.endUpdates()
            
            // Ensure layout pass fully completes
            tableView.layoutIfNeeded()

            // 2. Calculate height difference after insert
            let newContentHeight = tableView.contentSize.height
            let heightDifference = newContentHeight - previousContentHeight

            // 3. Adjust content offset to preserve visual position
            tableView.setContentOffset(CGPoint(x: previousOffset.x, y: previousOffset.y + heightDifference), animated: false)
        }
    }

    func insertedWithAnimation(sections: IndexSet, rows: [IndexPath]) {
        if sections.isEmpty && rows.isEmpty {
            return
        }
        log("inserted without scroll to")
        log("insertingSections with animation: \(sections), insertingRows: \(rows)")
        log("TableView state with animation: \(tableView.numberOfSections), data source state: \(viewModel?.historyVM.sections.count)")
        tableView.performBatchUpdates { [weak self] in
            if !sections.isEmpty {
                self?.tableView.insertSections(sections, with: .none)
            }
            if !rows.isEmpty {
                self?.tableView.insertRows(at: rows, with: .none)
            }
        }
    }
    
    func delete(sections: [IndexSet], rows: [IndexPath]) {
        log("deleted sections")
        tableView.performBatchUpdates {
            /// First, we have to delete rows to have the right index for rows,
            /// then we are ready to delete sections
            if !rows.isEmpty {
                tableView.deleteRows(at: rows, with: .fade)
            }
            
            if !sections.isEmpty {
                /// From newer section at bottom of theread to top to prevent crash
                sections.reversed().forEach { sectionSet in
                    tableView.deleteSections(sectionSet, with: .fade)
                }
            }
        }
    }
    
    func performBatchUpdateForReactions(_ indexPaths: [IndexPath]) async {
        return await withCheckedContinuation { continuation in
            performBatchUpdateForReactions(indexPaths) {
                continuation.resume(with: .success(()))
            }
        }
    }
    
    private func performBatchUpdateForReactions(_ indexPaths: [IndexPath], completion: @escaping () -> Void) {
        log("update reactions")

        tableView.performBatchUpdates { [weak self] in
            guard let self = self else {
                return
            }
            for indexPath in indexPaths {
                if let tuple = cellFor(indexPath: indexPath) {
                    tuple.cell.reactionsUpdated(viewModel: tuple.vm)
                }
            }
        } completion: { [weak self] completed in
            if completed {
                completion()
            }
        }
    }
    
    public func reactionDeleted(indexPath: IndexPath, reaction: Reaction) {
        log("reaciton deleted")
        if let tuple = cellFor(indexPath: indexPath) {
            tableView.beginUpdates()
            tuple.cell.reactionDeleted(reaction)
            tableView.endUpdates()
        }
    }
    
    public func reactionAdded(indexPath: IndexPath, reaction: Reaction) {
        log("reaction added")
        if let tuple = cellFor(indexPath: indexPath) {
            tableView.beginUpdates()
            tuple.cell.reactionAdded(reaction)
            tableView.endUpdates()
        }
    }
    
    public func reactionReplaced(indexPath: IndexPath, reaction: Reaction) {
        log("reaction replaced")
        if let tuple = cellFor(indexPath: indexPath) {
            tableView.beginUpdates()
            tuple.cell.reactionReplaced(reaction)
            tableView.endUpdates()
        }
    }
    
    func moveToOffset(_ offset: CGFloat) {
        tableView.setContentOffset(.init(x: 0, y: offset), animated: false)
    }
    
    private func cellFor(indexPath: IndexPath) -> (vm: MessageRowViewModel, cell: MessageBaseCell)?  {
        guard let cell = tableView.cellForRow(at: indexPath) as? MessageBaseCell else { return nil }
        guard let vm = sections.viewModelWith(indexPath) else { return nil }
        return (vm, cell)
    }
    
    private func log(_ message: String) {
        Logger.log(title: "ThreadViewController", message: "\(message)")
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
            Task { @MainActor in
                self?.willShowKeyboard(notif: notif)
            }
        }

        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { [weak self] notif in
            Task { @MainActor in
                self?.willHidekeyboard(notif: notif)
            }
        }
        tapGetsure.addTarget(self, action: #selector(hideKeyboard))
        tapGetsure.isEnabled = true
        view.addGestureRecognizer(tapGetsure)
    }
    
    private func willShowKeyboard(notif: Notification) {
        if isViewControllerVisible == false { return }
        keyboardAnimationTransaction(notif, show: true)
        
        /// Prevent overlaping with the text container if the thread is empty.
        if viewModel?.historyVM.sections.isEmpty == true {
            view.bringSubviewToFront(sendContainer)
        }
    }
    
    private func willHidekeyboard(notif: Notification) {
        if isViewControllerVisible == false { return }
        keyboardAnimationTransaction(notif, show: false)
    }
    
    private func keyboardAnimationTransaction(_ notif: Notification, show: Bool) {
        guard let tuple = notif.extractDurationAndAnimation() else { return }
        hasExternalKeyboard = tuple.rect.height <= 69
        keyboardheight = show ? tuple.rect.height : 0
        
        sendContainerBottomConstraint?.constant = show ? -keyboardheight : keyboardheight
       
        let pureHeight = sendContainer.bounds.height - sendContainer.safeAreaInsets.bottom
        let showInset = pureHeight + keyboardheight - view.safeAreaInsets.bottom
        let hideInset = pureHeight /// No need to use safeAreaInset because it will handeled by UIKit itself
        let insetBottom = show ? showInset : hideInset
        tableView.contentInset.bottom = insetBottom
        tableView.scrollIndicatorInsets.bottom = insetBottom
        
        /// Disable onHeightChanged callback for the send container
        /// to manipulate the content inset during the animation
        animatingKeyboard = true
        let indexPath = lastMessageIndexPathIfVisible()
        
        UIView.animate(withDuration: tuple.duration, delay: 0.0, options: tuple.opt) {
            /// Animate layout sendContainerBottomConstraint changes.
            /// It should be done on it's superView to animate
            self.view.layoutIfNeeded()
            
            // Scroll within the transaction block
            if let indexPath = indexPath {
                /// Animation parameter should be always set to false
                /// unless it won't animate as we expect in a UIView.animate block.
                self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: false)
            }
        } completion: { completed in
            if completed {
                self.animatingKeyboard = false
            }
        }
    }
    
    private func onSendHeightChanged(_ height: CGFloat) {
        let isButtonsVisible = viewModel?.sendContainerViewModel.getMode().type == .showButtonsPicker
        let safeAreaHeight = (isButtonsVisible ? 0 : view.safeAreaInsets.bottom)
        let height = (height - safeAreaHeight) + keyboardheight
        if tableView.contentInset.bottom != height {
            tableView.contentInset.bottom = height
        }
    }

    @objc private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

extension Notification: @unchecked @retroactive Sendable {
    func extractDurationAndAnimation() -> (duration: Double, opt: UIView.AnimationOptions, rect: CGRect)? {
        if let rect = userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
           let animationCurve = userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt,
           let duration = userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double
        {
            let opt = UIView.AnimationOptions(rawValue: animationCurve << 16)
            return (duration, opt, rect)
        }
        return nil
    }
}
