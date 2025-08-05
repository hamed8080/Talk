//
//  GetHistoryReuqester.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 6/9/25.
//

import Foundation
import Chat
import Combine

@MainActor
public class GetHistoryReuqester {
    private let KEY: String
    private var cancellableSet = Set<AnyCancellable>()
    public var mainData: MainRequirements?
    public weak var viewModel: ThreadViewModel?
    
    enum HistoryError: Error {
        case failed(ChatResponse<Sendable>)
    }
    
    public init(key: String) {
        self.KEY = "\(key)-\(UUID().uuidString)"
    }
    
    public func setup(data: MainRequirements, viewModel: ThreadViewModel?) {
        self.mainData = data
        self.viewModel = viewModel
    }
    
    public func get(_ req: GetHistoryRequest, queueable: Bool = false) async throws -> [MessageRowViewModel] {
        let key = KEY
        return try await withCheckedThrowingContinuation { [weak self] continuation in
            self?.sink(continuation)
            Task { @ChatGlobalActor [weak self] in
                RequestsManager.shared.append(prepend: key, value: req)
                if queueable {
                    await AppState.shared.objectsContainer.chatRequestQueue.enqueue(.history(req: req))
                } else {
                    await ChatManager.activeInstance?.message.history(req)
                }
            }
        }
    }
    
    private func sink(_ continuation: CheckedContinuation<[MessageRowViewModel], any Error>) {
        NotificationCenter.message.publisher(for: .message)
            .compactMap { $0.object as? MessageEventTypes }
            .sink { [weak self] event in
                Task { [weak self] in
                    if let result = await self?.handleEvent(event) {
                        continuation.resume(with: .success(result))
                    }
                }
            }
            .store(in: &cancellableSet)
        
        NotificationCenter.error.publisher(for: .error)
            .compactMap { $0.object as? ChatResponse<Sendable> }
            .sink { [weak self] resp in
                if let key = self?.KEY, resp.pop(prepend: key) != nil {
                    continuation.resume(throwing: HistoryError.failed(resp))
                }
            }
            .store(in: &cancellableSet)
    }
    
    private func handleEvent(_ event: MessageEventTypes) async -> [MessageRowViewModel]? {
        if case .history(let resp) = event, resp.pop(prepend: KEY) != nil, let messages = resp.result {
            return await calculateViewModels(messages.sortedByTime())
        }
        return nil
    }
    
    private func calculateViewModels(_ messages: [Message]) async -> [MessageRowViewModel] {
        guard let mainData = mainData else { return [] }
        return await MessageRowCalculators.batchCalulate(messages, mainData: mainData, viewModel: viewModel)
    }
}
