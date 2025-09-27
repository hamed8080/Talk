//
//  ThreadContentList.swift
//  Talk
//
//  Created by Hamed Hosseini on 6/5/21.
//

import Chat
import SwiftUI
import TalkUI
import TalkViewModels
import TalkModels

struct ThreadContentList: View {
    static var count = 0
    let container: ObjectsContainer
    @EnvironmentObject var threadsVM: ThreadsViewModel
    private var sheetBinding: Binding<Bool> { Binding(get: { threadsVM.sheetType != nil }, set: { _ in }) }
    @State private var twoRowTappedAtSameTime = false

    var body: some View {
        ThreadsTableViewControllerWrapper(viewModel: threadsVM)
            .safeAreaInset(edge: .top, spacing: 0) {
                ConversationTopSafeAreaInset()
            }
    }
}

#if DEBUG
private struct Preview: View {
    @State var container = ObjectsContainer(delegate: ChatDelegateImplementation.sharedInstance)

    var body: some View {
        NavigationStack {
            ThreadContentList(container: container)
                .environmentObject(container)
                .environmentObject(container.audioPlayerVM)
                .environmentObject(container.threadsVM)
                .environmentObject(AppState.shared)
                .task {
                    for thread in MockData.generateThreads(count: 5) {
                        await container.threadsVM.calculateAppendSortAnimate(thread)
                    }
                }
        }
    }
}
#endif
