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
public final class SendContainerViewModel: ObservableObject {
    private weak var viewModel: ThreadViewModel?
    private var thread: Conversation { viewModel?.thread ?? .init() }
    public var threadId: Int { thread.id ?? -1 }
    private var textMessage: String = ""
    /// We will need this for UserDefault purposes because ViewModel.thread is nil when the view appears.
    @Published private var mode: SendcContainerMode = .init(type: .voice)
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
        if let editMessage = getDraftEditMessage() {
            mode = .init(type: .edit, editMessage: editMessage)
        }
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
        mode = .init(type: .voice)
        setText(newValue: "")
        onTextChanged?(textMessage)
        setEditMessageDraft(nil)
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
        onTextChanged?(textMessage)
    }

    public func getText() -> String {
        textMessage.replacingOccurrences(of: RTLMarker, with: "")
    }

    public func setText(newValue: String) {
        textMessage = newValue
        onTextMessageChanged(newValue)
        
        /// just update the ui it will check by getter methods
        if mode.type != .edit {
            mode = .init(type: .voice)
        }
    }

    public func setEditMessage(message: Message?) {
        onEditMessageChanged(message)
        if let message = message {
            mode = .init(type: .edit, editMessage: message)
            setEditText(message)
        } else {
            mode = .init(type: .voice)
        }
    }

    public func getEditMessage() -> Message? {
        return mode.editMessage
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

    public func canShowMuteChannelBar() -> Bool {
        (thread.type?.isChannelType == true) &&
        (thread.admin == false || thread.admin == nil) &&
        !(mode.type == .edit)
    }

    public func showSendButton(mode: SendcContainerMode) -> Bool {
        !isTextEmpty() ||
        viewModel?.attachmentsViewModel.attachments.count ?? 0 > 0 ||
        hasForward() ||
        (mode.type == .edit && !isTextEmpty()) // when we add a peice of text to an empty image we should be able to show send button eventhough it's empty
    }

    private func hasForward() -> Bool {
        AppState.shared.appStateNavigationModel.forwardMessageRequest != nil
    }
    
    public func showCamera(mode: SendcContainerMode) -> Bool {
        mode.type == .video && !showSendButton(mode: mode)
    }
    
    public func showAudio(mode: SendcContainerMode) -> Bool {
        mode.type == .voice && !showSendButton(mode: mode)
    }
    
    public func disableButtonPicker(mode: SendcContainerMode) -> Bool {
        mode.type == .edit
    }
    
    private func setEditText(_ message: Message) {
        guard let text = message.message else { return }
        let isFirstRTL = isFirstCharacterRTL(string: text)
        onEditMessageChanged(message)
        onTextMessageChanged(message.message ?? "")
        textMessage = isFirstRTL ? "\(RTLMarker)\(text)" : text
        onTextChanged?(textMessage)
    }
    
    private func isFirstCharacterRTL(string: String) -> Bool {
        guard let char = string.replacingOccurrences(of: RTLMarker, with: "").first else { return false }
        return char.isEnglishCharacter == false
    }
    
    public func getMode() -> SendcContainerMode {
        return mode
    }
    
    public func setMode(type: SendcContainerMode.ModeType, editMessage: Message? = nil) {
        self.mode = .init(type: type, editMessage: editMessage)
    }
    
    public var modePublisher: Published<SendcContainerMode>.Publisher {
        return $mode
    }
}
