//
//  AddParticipantsToViewModel.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Chat
import Combine
import Foundation

final class AddParticipantsToViewModel: ObservableObject {
    @Published var isLoading = false
    @Published private(set) var model = StartThreadModel()
    private(set) var cancellableSet: Set<AnyCancellable> = []

    init() {
        AppState.shared.$connectionStatus.sink { [weak self] status in
            if self?.model.threads.count == 0, status == .connected {}
        }
        .store(in: &cancellableSet)
    }

    func setupPreview() {
        model.setupPreview()
    }
}
