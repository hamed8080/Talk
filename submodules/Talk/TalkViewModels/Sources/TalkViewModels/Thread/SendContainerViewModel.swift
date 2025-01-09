//
//  SendContainerViewModel.swift
//  TalkViewModels
//
//  Created by hamed on 10/22/22.
//

import Foundation
import Chat
import Combine
import TalkModels

@MainActor
public final class SendContainerViewModel {
    private weak var viewModel: ThreadViewModel?
    private var thread: Conversation { viewModel?.thread ?? .init() }
    public var threadId: Int { thread.id ?? -1 }
    private var textMessage: String = ""
    private var cancelable: Set<AnyCancellable> = []
    public var isInEditMessageMode: Bool = false
    /// We will need this for UserDefault purposes because ViewModel.thread is nil when the view appears.
    public private(set) var showPickerButtons: Bool = false
    public private(set) var isVideoRecordingSelected = false
    private var editMessage: Message?
    public var height: CGFloat = 0
    private let draftManager = DraftManager.shared
    public var onTextChanged: ((String?) -> Void)?
    private let RTLMarker = "\u{200f}"

    public init() {}

    public func setup(viewModel: ThreadViewModel) {
        self.viewModel = viewModel
        let contactId = AppState.shared.appStateNavigationModel.userToCreateThread?.contactId ?? -1
        let textMessage = draftManager.get(threadId: threadId) ?? draftManager.get(contactId: contactId) ?? ""
        setText(newValue: textMessage)
        editMessage = getDraftEditMessage()
    }

    private func onTextMessageChanged(_ newValue: String) {
        viewModel?.mentionListPickerViewModel.text = textMessage
        if !isTextEmpty() {
            viewModel?.sendStartTyping(textMessage)
        }
        let isRTLChar = textMessage.count == 1 && textMessage.first == Character(RTLMarker)
        if !isTextEmpty() && !isRTLChar {
            setDraft(newText: newValue)
        } else {
            setDraft(newText: "")
        }
    }

    public func clear() {
        setText(newValue: "")
        editMessage = nil
        isInEditMessageMode = false
    }

    public func isTextEmpty() -> Bool {
        let sanitizedText = textMessage.replacingOccurrences(of: RTLMarker, with: "").trimmingCharacters(in: .whitespacesAndNewlines)
        return sanitizedText.isEmpty
    }

    public func addMention(_ participant: Participant) {
        let userName = (participant.username ?? "")
        var text = textMessage
        if let lastIndex = text.lastIndex(of: "@") {
            text.removeSubrange(lastIndex..<text.endIndex)
        }
        setText(newValue: "\(text)@\(userName) ") // To hide participants dialog
    }

    public func getText() -> String {
        textMessage.replacingOccurrences(of: RTLMarker, with: "")
    }

    public func setText(newValue: String) {
        textMessage = newValue
        onTextMessageChanged(newValue)
        onTextChanged?(newValue)
    }

    public func setEditMessage(message: Message?) {
        self.editMessage = message
        isInEditMessageMode = message != nil
    }

    public func getEditMessage() -> Message? {
        return editMessage
    }

    public func showPickerButtons(_ show: Bool) {
        showPickerButtons = show
    }

    public func toggleVideorecording() {
        isVideoRecordingSelected.toggle()
    }

    public func cancelAllObservers() {
        cancelable.forEach { cancelable in
            cancelable.cancel()
        }
    }

    public func setDraft(newText: String) {
        if !isSimulated() {
            draftManager.set(draftValue: newText, threadId: threadId)
        } else if let contactId = AppState.shared.appStateNavigationModel.userToCreateThread?.contactId {
            draftManager.set(draftValue: newText, contactId: contactId)
        }
    }

    /// If we are in edit mode drafts will not be changed.
    private func onEditMessageChanged(_ editMessage: Message?) {
        if editMessage != nil {
            let text = editMessage?.message ?? ""

            /// set edit message draft for the thread
            setEditMessageDraft(editMessage)

            /// It will trigger onTextMessageChanged method
            if draftManager.get(threadId: threadId) == nil {
                setText(newValue: text)
            }
        } else {
            setEditMessageDraft(nil)
        }
    }

    private func setEditMessageDraft(_ editMessage: Message?) {
        draftManager.setEditMessageDraft(editMessage, threadId: threadId)
    }

    private func getDraftEditMessage() -> Message? {
        draftManager.editMessageText(threadId: threadId)
    }

    private func isSimulated() -> Bool {
        threadId == -1 || threadId == LocalId.emptyThread.rawValue
    }

    public func setAttachmentButtonsVisibility(show: Bool) {
        showPickerButtons = show
    }

    public func canShowMuteChannelBar() -> Bool {
        (thread.type?.isChannelType == true) &&
        (thread.admin == false || thread.admin == nil) &&
        !isInEditMessageMode
    }
    
    public func disableSend() -> Bool {
        thread.disableSend && isInEditMessageMode == false && !canShowMuteChannelBar()
    }

    public func showSendButton() -> Bool {
        !isTextEmpty() ||
        viewModel?.attachmentsViewModel.attachments.count ?? 0 > 0 ||
        hasForward()
    }

    private func hasForward() -> Bool {
        AppState.shared.appStateNavigationModel.forwardMessageRequest != nil
    }

    public func showCamera() -> Bool {
        isTextEmpty() && isVideoRecordingSelected
    }

    public func showAudio() -> Bool {
        isTextEmpty() && !isVideoRecordingSelected && isVoice() && !hasForward()
    }

    public func isVoice() -> Bool {
        viewModel?.attachmentsViewModel.attachments.count == 0
    }

    public func showRecordingView() -> Bool {
        viewModel?.audioRecoderVM.isRecording == true || viewModel?.audioRecoderVM.recordingOutputPath != nil
    }
}
