//
//  ThreadsViewModel+MuteThread.swift
//  TalkViewModels
//
//  Created by hamed on 11/24/22.
//

import Chat
import Foundation

@MainActor
protocol MuteThreadProtocol {
    func toggleMute(_ thread: Conversation)
    func mute(_ threadId: Int)
    func unmute(_ threadId: Int)
}

extension ThreadsViewModel: MuteThreadProtocol {
    public func toggleMute(_ thread: Conversation) {
        guard let threadId = thread.id else { return }
        if thread.mute ?? false == false {
            mute(threadId)
        } else {
            unmute(threadId)
        }
    }

    public func mute(_ threadId: Int) {
        Task { @ChatGlobalActor in
            ChatManager.activeInstance?.conversation.mute(.init(subjectId: threadId))
        }
    }

    public func unmute(_ threadId: Int) {
        Task { @ChatGlobalActor in
            ChatManager.activeInstance?.conversation.unmute(.init(subjectId: threadId))
        }
    }

    public func onMuteThreadChanged(mute: Bool, threadId: Int?) async {
        if let index = firstIndex(threadId) {
            threads[index].mute = mute
            await sortInPlace()
            let activeVM = AppState.shared.objectsContainer.navVM.presentedThreadViewModel
            if activeVM?.viewModel.threadId == threadId {
                activeVM?.viewModel.thread.mute = mute
                activeVM?.viewModel.delegate?.muteChanged()
            }
            animateObjectWillChange()
        }
    }
}
