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
        ScrollViewReader { reader in
            List {
                ForEach(threadsVM.threads) { thread in
                    ThreadRow() {
                        onTap(thread)
                    }
                    .id(thread.id)
                    .environmentObject(thread)
                    .listRowInsets(.init(top: 16, leading: 0, bottom: 16, trailing: 8))
                    .listRowSeparatorTint(Color.App.dividerSecondary)
                    .listRowBackground(ThreadListRowBackground().environmentObject(thread))
                    .onAppear {
                        Task {
                            await threadsVM.loadMore(id: thread.id)
                        }
                    }
                }
                loadingView
            }
            .listStyle(.plain)
            .environment(\.defaultMinListRowHeight, 0)
            .background(Color.App.bgPrimary)
            .animation(.easeInOut, value: threadsVM.threads.count)
            .animation(.easeInOut, value: threadsVM.lazyList.isLoading)
            .overlay(ThreadListShimmer().environmentObject(threadsVM.shimmerViewModel))
            .safeAreaInset(edge: .top, spacing: 0) {
                ConversationTopSafeAreaInset()
            }
            .sheet(isPresented: sheetBinding) {
                ThreadsSheetFactoryView()
            }
            .refreshable {
                Task {
                    await threadsVM.refresh()
                }
            }
            .onReceive(threadsVM.$scrollToId) { newValue in
                if let newId = newValue {
                    withAnimation {
                        reader.scrollTo(newId, anchor: .top)
                    }
                }
            }
        }
    }

    private var loadingView: some View {
        ListLoadingView(isLoading: .constant(threadsVM.lazyList.isLoading && threadsVM.firstSuccessResponse == true))
            .id(UUID())
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .listRowInsets(.zero)
    }
    
    private func onTap(_ thread: CalculatedConversation) {
        /// Ignore opening the same thread on iPad/MacOS, if so it will lead to a bug.
        if thread.id == AppState.shared.objectsContainer.navVM.presentedThreadViewModel?.threadId { return }
        
        if !twoRowTappedAtSameTime {
            twoRowTappedAtSameTime = true
            Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { _ in
                Task { @MainActor in
                    twoRowTappedAtSameTime = false
                }
            }
            /// to update isSeleted for bar and background color
            threadsVM.setSelected(for: thread.id ?? -1, selected: true, isArchive: thread.isArchive == true)
            AppState.shared.objectsContainer.navVM.switchFromThreadList(thread: thread.toStruct())
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
