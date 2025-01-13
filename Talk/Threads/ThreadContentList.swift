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
        List {
            ForEach(threadsVM.threads) { thread in
                ThreadRow() {
                    onTap(thread)
                }
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
    }

    private var loadingView: some View {
        ListLoadingView(isLoading: .constant(threadsVM.lazyList.isLoading && threadsVM.firstSuccessResponse == true))
            .id(UUID())
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .listRowInsets(.zero)
    }
    
    private func onTap(_ thread: CalculatedConversation) {
        if !twoRowTappedAtSameTime {
            twoRowTappedAtSameTime = true
            Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { _ in
                twoRowTappedAtSameTime = false
            }
            /// to update isSeleted for bar and background color
            threadsVM.setSelected(for: thread.id ?? -1, selected: true)
            AppState.shared.objectsContainer.navVM.switchFromThreadList(thread: thread.toStruct())
        }
    }
}

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
                    if let fileURL = Bundle.main.url(forResource: "new_message", withExtension: "mp3") {
                        try? container.audioPlayerVM.setup(fileURL: fileURL, ext: "mp3", title: "Note")
                        container.audioPlayerVM.toggle()
                    }
                }
        }
    }
}

struct ThreadContentList_Previews: PreviewProvider {
    struct AudioPlayerPreview: View {
        @ObservedObject var audioPlayerVm = AVAudioPlayerViewModel()

        var body: some View {
            AudioPlayerView()
                .environmentObject(audioPlayerVm)
                .onAppear {
                    try? audioPlayerVm.setup(fileURL: URL(string: "https://www.google.com")!, ext: "mp3", title: "Note", subtitle: "Test")
                    audioPlayerVm.isClosed = false
                }
        }
    }

    static var previews: some View {
        AudioPlayerPreview()
            .previewDisplayName("AudioPlayerPreview")
        Preview()
    }
}
