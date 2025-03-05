//
//  BotViewModel.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Chat
import Combine
import SwiftUI
import TalkModels

@MainActor
public final class BotViewModel: ObservableObject {
    @Published public var bots: [BotInfo] = []
    @Published public var selectedBot: BotInfo?
    @Published public var isLoading = false
    public private(set) var firstSuccessResponse = false
    private var cancelable: Set<AnyCancellable> = []

    public init() {
        AppState.shared.$connectionStatus
            .sink { [weak self] event in
                self?.onConnectionStatusChanged(event)
            }
            .store(in: &cancelable)
        NotificationCenter.bot.publisher(for: .bot)
            .compactMap { $0.object as? BotEventTypes }
            .sink { [weak self] value in
                self?.onBotEvent(value)
            }
            .store(in: &cancelable)
        getBotList()
    }

    private func onBotEvent(_ event: BotEventTypes) {
        switch event {
        case .bots(let response):
            onBots(response)
        case .start(let response):
            onStart(response)
        case .stop(let response):
            onStop(response)
        case .create(let response):
            onCreate(response)
        default:
            break
        }
    }

    public func onConnectionStatusChanged(_ status: Published<ConnectionStatus>.Publisher.Output) {
        if firstSuccessResponse == false, status == .connected {
            getBotList()
        }
    }

    public func onBots(_ response: ChatResponse<[BotInfo]>) {
        if let bots = response.result {
            firstSuccessResponse = true
            appendBots(bots: bots)
        }
        isLoading = false
    }

    public func onStart(_ response: ChatResponse<String>) {
        if let name = response.result, let bot = bots.first(where: {$0.name == name}) {
            removeBot(bot)
        }
        isLoading = false
    }

    public func onStop(_ response: ChatResponse<String>) {
        if response.result != nil {

        }
        isLoading = false
    }

    public func onCreate(_ response: ChatResponse<BotInfo>) {
        if response.pop() != nil {
            appendBots(bots: [.init(name: response.result?.name, botUserId: response.result?.botUserId)])
        }
        isLoading = false
    }

    public func getBotList() {
        let req = GetUserBotsRequest()
        RequestsManager.shared.append(value: req)
        Task { @ChatGlobalActor in
            ChatManager.activeInstance?.bot.get(req)
        }
    }

    public func stopBot(_ bot: BotInfo, threadId: Int) {
        guard let name = bot.name else { return }
        let req = StartStopBotRequest(botName: name, threadId: threadId)
        RequestsManager.shared.append(value: req)
        Task { @ChatGlobalActor in
            ChatManager.activeInstance?.bot.stop(req)
        }
    }

    public func startBot(_ bot: BotInfo, threadId: Int) {
        guard let name = bot.name else { return }
        let req = StartStopBotRequest(botName: name, threadId: threadId)
        RequestsManager.shared.append(value: req)
        Task { @ChatGlobalActor in
            ChatManager.activeInstance?.bot.start(req)
        }
    }

    public func refresh() {
        clear()
        getBotList()
    }

    public func clear() {
        bots = []
        selectedBot = nil
    }

    public func createBot(name: String) {
        isLoading = true
        let req = CreateBotRequest(botName: name)
        RequestsManager.shared.append(value: req)
        Task { @ChatGlobalActor in
            ChatManager.activeInstance?.bot.create(req)
        }
    }

    public func appendBots(bots: [BotInfo]) {
        // remove older data to prevent duplicate on view
        bots.forEach { bot in
            if let oldIndex = self.bots.firstIndex(where: { $0.botUserId == bot.botUserId }) {
                self.bots[oldIndex] = bot
            } else {
                self.bots.append(bot)
            }
        }
    }

    public func setSelectedBot(bot: BotInfo?, isSelected _: Bool) {
        selectedBot = bot
    }

    public func removeBot(_ bot: BotInfo) {
        bots.removeAll(where: { $0.botUserId == bot.botUserId })
    }

}
