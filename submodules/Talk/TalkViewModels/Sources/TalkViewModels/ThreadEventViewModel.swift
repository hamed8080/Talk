//
//  ThreadEventViewModel
//  TalkViewModels
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Chat
import Foundation
import TalkExtensions

@MainActor
public final class ThreadEventViewModel: ObservableObject {
    @Published public var isShowingEvent: Bool = false
    public var threadId: Int
    public var smt: SMT?
    private var lastEventTime = Date()
    
    public nonisolated init(threadId: Int) {
        self.threadId = threadId
    }

    public func startEventTimer(_ event: SystemEventMessageModel) {
        if isShowingEvent == false {
            lastEventTime = Date()
            isShowingEvent = true
            self.smt = event.smt
            setActiveThreadSubtitle()
            Task.detached { [weak self] in
                try? await Task.sleep(for: .seconds(1))
                await self?.handleTimer()
            }
        } else {
            lastEventTime = Date()
        }
    }
    
    private func handleTimer() {
        if lastEventTime.advanced(by: 1) < Date() {
            self.isShowingEvent = false
            self.smt = nil
            setActiveThreadSubtitle()
        }
    }

    private func setActiveThreadSubtitle() {
        let activeThread = AppState.shared.objectsContainer.navVM.viewModel(for: threadId)
        activeThread?.conversationSubtitle.setEvent(smt: smt)
    }
}
