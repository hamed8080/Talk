//
//  ThreadEventViewModel
//  TalkViewModels
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Chat
import Foundation

public final class ThreadEventViewModel: ObservableObject {
    @Published public var isShowingEvent: Bool = false
    public var threadId: Int
    public var smt: SMT?
    private var lastEventTime = Date()
    public init(threadId: Int) {
        self.threadId = threadId
    }

    public func startEventTimer(_ event: SystemEventMessageModel) {
        if isShowingEvent == false {
            lastEventTime = Date()
            isShowingEvent = true
            self.smt = event.smt
            setActiveThreadSubtitle()
            Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
                if let self = self, self.lastEventTime.advanced(by: 1) < Date() {
                    timer.invalidate()
                    self.isShowingEvent = false
                    self.smt = nil
                    setActiveThreadSubtitle()
                }
            }
        } else {
            lastEventTime = Date()
        }
    }

    private func setActiveThreadSubtitle() {
        let activeThread = AppState.shared.objectsContainer.navVM.viewModel(for: threadId)
        activeThread?.conversationSubtitle.setEvent(smt: smt)
    }
}
