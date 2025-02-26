//
//  BanViewModel.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 2/22/25.
//

import Foundation
import Chat
import Combine
import TalkModels

@MainActor
public class BanViewModel: ObservableObject {
    private var cancelable = Set<AnyCancellable>()
    private var banError: BanError? = nil
    @Published public var timerValue: TimeInterval = 0
    private var timer: Timer?
    
    public init () {
        registerEvent()
    }
    
    private func registerEvent() {
        NotificationCenter.error.publisher(for: .error)
            .sink { notif in
                if let response = notif.object as? ChatResponse<Sendable> {
                    self.handelBanError(response: response)
                }
            }
            .store(in: &cancelable)
    }
    
    private func handelBanError(response: ChatResponse<Sendable>) {
        guard let error = response.error,
              let code = error.code,
              ServerErrorType(rawValue: code) == .temporaryBan,
              let data = error.message?.data(using: .utf8),
              let banError = try? JSONDecoder.instance.decode(BanError.self, from: data),
              timerValue == 0
        else { return }
        /// We added 0.5 seconds to make sure the server will accept our request.
        timerValue = (TimeInterval(banError.duration ?? 0) / 1000) + 0.5
        self.banError = banError
        startTimer()
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.onTimerTick()
            }
        }
    }
    
    private func onTimerTick() {
        /// Reduce on update the UI
        timerValue -= 1
        
        /// Finished
        if timerValue <= 0 {
            timer?.invalidate()
            timer = nil
            timerValue = 0
            banError = nil
            AppState.shared.objectsContainer.appOverlayVM.dialogView(canDismiss: false, view: nil)
        }
    }
}
