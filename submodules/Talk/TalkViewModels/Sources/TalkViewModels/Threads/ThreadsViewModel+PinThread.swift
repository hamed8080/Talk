//
//  ThreadsViewModel+PinThread.swift
//  TalkViewModels
//
//  Created by hamed on 11/24/22.
//

import Chat
import Foundation

@MainActor
protocol PinThreadProtocol {
    func togglePin(_ thread: Conversation)
    func pin(_ threadId: Int)
    func unpin(_ threadId: Int)
    func onPin(_ response: ChatResponse<Conversation>)
    func onUNPin(_ response: ChatResponse<Conversation>)
}

extension ThreadsViewModel: PinThreadProtocol {
    public func togglePin(_ thread: Conversation) {
        guard let threadId = thread.id else { return }
        if thread.pin == false {
            pin(threadId)
        } else {
            unpin(threadId)
        }
    }

    public func pin(_ threadId: Int) {
        Task { @ChatGlobalActor in
            ChatManager.activeInstance?.conversation.pin(.init(subjectId: threadId))
        }
    }

    public func unpin(_ threadId: Int) {
        Task { @ChatGlobalActor in
            ChatManager.activeInstance?.conversation.unpin(.init(subjectId: threadId))
        }
    }

    public func onPin(_ response: ChatResponse<Conversation>) {
        serverSortedPins.insert(response.result?.id ?? -1, at: 0)
        if response.result != nil, let threadIndex = firstIndex(response.result?.id) {
            threads[threadIndex].pin?.toggle()
            sort()
            animateObjectWillChange()
        }
        getNotActiveThreads(response.result)
    }

    public func onUNPin(_ response: ChatResponse<Conversation>) {
        if response.result != nil, let threadIndex = firstIndex(response.result?.id) {
            serverSortedPins.removeAll(where: {$0 == response.result?.id})
            threads[threadIndex].pin?.toggle()
            sort()
            animateObjectWillChange()
        }
    }
}
