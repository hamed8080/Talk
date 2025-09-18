//
//  SelfThreadBuilder.swift
//  TalkViewModels
//
//  Created by hamed on 10/22/22.
//

import Foundation
import Chat
import Combine
import TalkModels

@MainActor
public class SelfThreadBuilder {
    private let id: String = "CREATE-SELF-THREAD-\(UUID().uuidString)"
    private var cancelable: Set<AnyCancellable> = []
    public typealias CompletionHandler = (Conversation) -> Void
    private var completion: CompletionHandler?

    public init(){
        registerNotifications()
    }

    public func create(completion: CompletionHandler? = nil) {
        self.completion = completion
        let title = "Thread.selfThread".bundleLocalized()
        let req = CreateThreadRequest(title: title, type: StrictThreadTypeCreation.selfThread.threadType)
        RequestsManager.shared.append(prepend: id, value: req)
        Task { @ChatGlobalActor in
            ChatManager.activeInstance?.conversation.create(req)
        }
    }

    private func onCreated(_ response: ChatResponse<Conversation>) {
        guard response.pop(prepend: id) != nil, let conversation = response.result, conversation.type == .selfThread else { return }
        UserDefaults.standard.setValue(codable: conversation, forKey: "SELF_THREAD")
        UserDefaults.standard.synchronize()
        completion?(conversation)
    }

    private func registerNotifications() {
        NotificationCenter.thread.publisher(for: .thread)
            .compactMap { $0.object as? ThreadEventTypes }
            .sink { [weak self] event in
                self?.onThreadEvent(event)
            }
            .store(in: &cancelable)
        
        AppState.shared.$connectionStatus.sink { [weak self]  newState in
            if newState == .connected, self?.cachedSlefConversation  == nil {
                self?.create()
            }
        }.store(in: &cancelable)
    }

    private func onThreadEvent(_ event: ThreadEventTypes?) {
        if case .created(let response) = event {
            onCreated(response)
        }
    }
    
    public var cachedSlefConversation: Conversation? {
        return UserDefaults.standard.codableValue(forKey: "SELF_THREAD")
    }
}
