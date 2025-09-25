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
    func onPin(_ response: ChatResponse<Conversation>) async
    func onUNPin(_ response: ChatResponse<Conversation>) async
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

    public func onPin(_ response: ChatResponse<Conversation>) async {
        serverSortedPins.insert(response.result?.id ?? -1, at: 0)
        if response.result != nil, let threadIndex = firstIndex(response.result?.id) {
            threads[threadIndex].pin?.toggle()
            delegate?.reloadCellWith(conversation: threads[threadIndex])
            
            threads[threadIndex].animateObjectWillChange()
            await sortInPlace()
            delegate?.updateUI(animation: true, reloadSections: false)
            animateObjectWillChange()
        }
        if let conversation = await threadFinder.getNotActiveThreads(response.result?.id ?? -1) {
            
        }
    }

    public func onUNPin(_ response: ChatResponse<Conversation>) async {
        if response.result != nil, let threadIndex = firstIndex(response.result?.id) {
            serverSortedPins.removeAll(where: {$0 == response.result?.id})
            threads[threadIndex].pin?.toggle()
            delegate?.reloadCellWith(conversation: threads[threadIndex])
            threads[threadIndex].animateObjectWillChange()
            await sortInPlace()
            delegate?.updateUI(animation: true, reloadSections: false)
            animateObjectWillChange()
        }
    }
}
