//
//  ErrorHandlerViewModel.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Foundation
import Combine
import SwiftUI
import Chat

@MainActor
public final class ErrorHandlerViewModel: ObservableObject {
    public private(set) var cancellable: Set<AnyCancellable> = []

    init() {
        NotificationCenter.error.publisher(for: .error)
            .compactMap { $0.object as? ChatResponse<Sendable> }
            .sink { [weak self] event in
                self?.onError(event)
            }
            .store(in: &cancellable)
    }

    public func onError(_ response: ChatResponse<Sendable>) {
        if let code = response.error?.code,
           code == ServerErrorType.noOtherOwnership.rawValue,
           let request = response.pop(prepend: "LEAVE") as? LeaveThreadRequest,
           let thread = AppState.shared.objectsContainer.threadsVM.threads.first(where: {$0.id == request.threadId})
        {
            let message = thread.type?.isChannelType == true ? "Thread.onlyChannelAdminError" : "Thread.onlyGroupAdminError"
            AppState.shared.objectsContainer.appOverlayVM.toast(leadingView: nil,
                                                                message: message,
                                                                messageColor: .red)
        }
    }
}
