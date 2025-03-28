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
    private var sections: ContiguousArray<MessageSection> { viewModel?.historyVM.sectionsHolder.sections ?? [] }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureViews()
        registerKeyboard()
        viewModel?.delegate = self
        viewModel?.historyVM.delegate = self
        viewModel?.historyVM.sectionsHolder.delegate = self
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
            viewModel.threadsViewModel?.setSelected(for: viewModel.threadId, selected: false)
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
        }
    }
    
    private func onSendHeightChanged(_ height: CGFloat, duration: Double = 0.25, options: UIView.AnimationOptions = []) {
        let isButtonsVisible = viewModel?.sendContainerViewModel.getMode().type == .showButtonsPicker
        let safeAreaHeight = (isButtonsVisible ? 0 : view.safeAreaInsets.bottom)
        let height = (height - safeAreaHeight) + keyboardheight
        if tableView.contentInset.bottom != height {
            tableView.contentInset = .init(top: topThreadToolbar.bounds.height + 4, left: 0, bottom: height, right: 0)
            Task {
                await viewModel?.scrollVM.scrollToLastMessageOnlyIfIsAtBottom()
            }
            UIView.animate(withDuration: duration, delay: 0, options: options) { [weak self] in
                self?.view.layoutIfNeeded()
            } completion: {  completed in
                if completed {}
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
        emptyThreadView.show(show, parent: view)
        if show {
            self.unreadMentionsButton.showWithAniamtion(false)
            self.moveToBottom.show(false)
            view.bringSubviewToFront(vStackOverlayButtons)
        }
    }
}

// MARK: ThreadViewDelegate
extension ThreadViewController: ThreadViewDelegate {
    
    func showMoveToButtom(show: Bool) {
        moveToBottom.show(show)
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
        self.moveToBottom.show(!appeared)
        if self.viewModel?.scrollVM.isAtBottomOfTheList == true {
            self.tableView.tableFooterView = nil
        } else {
            self.tableView.tableFooterView = self.loadingManager.getBottomLoadingContainer()
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
        AppState.shared.objectsContainer.appOverlayVM.dialogView = AnyView(
            DatePickerWrapper(hideControls: false) { [weak self] date in
                Task {
                    await self?.viewModel?.historyVM.moveToTimeByDate(time: UInt(date.millisecondsSince1970))
                    AppState.shared.objectsContainer.appOverlayVM.dialogView = nil
                }
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

    func updateThumbnail(at: IndexPath, viewModel: MessageRowViewModel) {
        guard let cell = tableView.cellForRow(at: at) as? MessageBaseCell else { return }
        cell.updateThumbnail(viewModel: viewModel)
    }

    func updateReplyImageThumbnail(at: IndexPath, viewModel: MessageRowViewModel) {
        guard let cell = tableView.cellForRow(at: at) as? MessageBaseCell else { return }
        cell.updateReplyImageThumbnail(viewModel: viewModel)
    }

    func inserted(at: IndexPath) {
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
        inserted(sections: sections, rows: rows, animate: animate, scrollTo: scrollTo)
    }

    private func inserted(sections: IndexSet, rows: [IndexPath], animate: UITableView.RowAnimation = .top, scrollTo: IndexPath?) {
        if let scrollTo = scrollTo {
            UIView.performWithoutAnimation {
                tableView.beginUpdates()
                tableView.insertSections(sections, with: .none)
                tableView.insertRows(at: rows, with: .none)
                tableView.endUpdates()
            }
            tableView.scrollToRow(at: scrollTo, at: .top, animated: false)
        } else {
            if sections.isEmpty && rows.isEmpty { return }
            tableView.performBatchUpdates { [weak self] in
                // Insert the sections and rows without animation
                if !sections.isEmpty {
                    self?.tableView.insertSections(sections, with: .none)
                }
                if !rows.isEmpty {
                    self?.tableView.insertRows(at: rows, with: .none)
                }
            }
        }
    }
    
    func delete(sections: [IndexSet], rows: [IndexPath]) {
        tableView.performBatchUpdates {
            /// Firstly, we have ato delete rows to have right index for rows,
            /// then we are prepared to delete sections
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
    
    func performBatchUpdateForReactions(_ indexPaths: [IndexPath]) {
        viewModel?.historyVM.isUpdating = true
        tableView.performBatchUpdates { [weak self] in
            guard let self = self else { return }
            for indexPath in indexPaths {
                if let tuple = cellFor(indexPath: indexPath) {
                    tuple.cell.reactionsUpdated(viewModel: tuple.vm)
                }
            }
        } completion: { [weak self] completed in
            self?.viewModel?.historyVM.isUpdating = false
        }
    }
    
    public func reactionDeleted(indexPath: IndexPath, reaction: Reaction) {
        if let tuple = cellFor(indexPath: indexPath) {
            tableView.beginUpdates()
            tuple.cell.reactionDeleted(reaction)
            tableView.endUpdates()
        }
    }
    
    public func reactionAdded(indexPath: IndexPath, reaction: Reaction) {
        if let tuple = cellFor(indexPath: indexPath) {
            tableView.beginUpdates()
            tuple.cell.reactionAdded(reaction)
            tableView.endUpdates()
        }
    }
    
    public func reactionReplaced(indexPath: IndexPath, reaction: Reaction) {
        if let tuple = cellFor(indexPath: indexPath) {
            tableView.beginUpdates()
            tuple.cell.reactionReplaced(reaction)
            tableView.endUpdates()
        }
    }
    
    private func cellFor(indexPath: IndexPath) -> (vm: MessageRowViewModel, cell: MessageBaseCell)?  {
        guard let cell = tableView.cellForRow(at: indexPath) as? MessageBaseCell else { return nil }
        guard let vm = sections.viewModelWith(indexPath) else { return nil }
        return (vm, cell)
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

        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in
                self?.willHidekeyboard()
            }
        }
        tapGetsure.addTarget(self, action: #selector(hideKeyboard))
        tapGetsure.isEnabled = true
        view.addGestureRecognizer(tapGetsure)
    }
    
    private func willShowKeyboard(notif: Notification) {
        if isViewControllerVisible == false { return }
        if let rect = notif.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
           let animationCurve = notif.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt,
           let duration = notif.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double
        {
            let animationOptions = UIView.AnimationOptions(rawValue: animationCurve << 16)
            if rect.size.height <= 69 {
                hasExternalKeyboard = true
            } else {
                hasExternalKeyboard = false
            }

            sendContainerBottomConstraint?.constant = -rect.height
            keyboardheight = rect.height
            onSendHeightChanged(sendContainer.frame.height, duration: duration, options: animationOptions)
            UIView.animate(withDuration: duration, delay: 0 , options: animationOptions) {
                self.view.layoutIfNeeded()
            } completion: { completed in
                if completed {
                    self.moveTolastMessageIfVisible()
                }
            }
        }
    }
        
    private func willHidekeyboard() {
        if isViewControllerVisible == false { return }
        sendContainerBottomConstraint?.constant = 0
        keyboardheight = 0
        hasExternalKeyboard = false
        onSendHeightChanged(sendContainer.frame.height)
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
        if let firstVisible = tableView.indexPathsForVisibleRows?.first, let previousIndexPath = sections.previousIndexPath(firstVisible) {
            let cell = tableView.cellForRow(at: previousIndexPath) as? MessageBaseCell
            return cell
        }
        return nil
    }

    private func nextVisibleIndexPath() -> MessageBaseCell? {
        if let lastVisible = tableView.indexPathsForVisibleRows?.last, let nextIndexPath = sections.nextIndexPath(lastVisible) {
            let cell = tableView.cellForRow(at: nextIndexPath) as? MessageBaseCell
            return cell
        }
        return nil
    }
}
