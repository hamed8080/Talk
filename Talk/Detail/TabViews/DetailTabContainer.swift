//
//  DetailTabContainer.swift
//  Talk
//
//  Created by hamed on 5/6/24.
//

import SwiftUI
import TalkViewModels
import TalkUI
import Chat

struct DetailTabContainer: View {
    @EnvironmentObject var viewModel: ThreadDetailViewModel
    @State private var tabs: [TalkUI.Tab] = []
    @State private var selectedTabIndex = 0

    var body: some View {
        CustomDetailTabView(tabs: tabs, tabButtons: { tabButtons } )
            .environmentObject(viewModel.threadVM?.participantsViewModel ?? .init())
            .selectedTabIndx(index: selectedTabIndex)
            .onAppear {
                makeTabs()
            }
            .onChange(of: viewModel.thread?.closed) { newValue in
                if newValue == true {
                    withAnimation {
                        makeTabs()
                    }
                }
            }
    }

    private var tabButtons: TabViewButtonsContainer {
        TabViewButtonsContainer(selectedTabIndex: $selectedTabIndex, tabs: tabs)
    }

    private func makeTabs() {
        if let thread = viewModel.thread {
            var tabs: [TalkUI.Tab] = [
                .init(title: "Thread.Tabs.members", view: AnyView(MemberView().ignoresSafeArea(.all))),
                .init(title: "Thread.Tabs.photos", view: AnyView(PictureView(conversation: thread, messageType: .podSpacePicture))),
                .init(title: "Thread.Tabs.videos", view: AnyView(VideoView(conversation: thread, messageType: .podSpaceVideo))),
                .init(title: "Thread.Tabs.music", view: AnyView(MusicView(conversation: thread, messageType: .podSpaceSound))),
                .init(title: "Thread.Tabs.voice", view: AnyView(VoiceView(conversation: thread, messageType: .podSpaceVoice))),
                .init(title: "Thread.Tabs.file", view: AnyView(FileView(conversation: thread, messageType: .podSpaceFile))),
                .init(title: "Thread.Tabs.link", view: AnyView(LinkView(conversation: thread, messageType: .link))),
            ]
            if thread.group == false || thread.group == nil {
                tabs.removeAll(where: {$0.title == "Thread.Tabs.members"})
            }
            if thread.group == true, thread.type?.isChannelType == true, (thread.admin == false || thread.admin == nil) {
                tabs.removeAll(where: {$0.title == "Thread.Tabs.members"})
            }

            let canShowMutalTab = thread.group == false && thread.type != .selfThread
            if canShowMutalTab {
                let view = AnyView(MutualThreadsView().ignoresSafeArea(.all).environmentObject(viewModel.mutualGroupsVM))
                tabs.append(.init(title: "Thread.Tabs.mutualgroup", view: view))
            }

            if thread.closed == true {
                tabs.removeAll(where: {$0.title == "Thread.Tabs.members"})
            }
            //        if thread.group == true || thread.type == .selfThread || !EnvironmentValues.isTalkTest {
            //            tabs.removeAll(where: {$0.title == "Thread.Tabs.mutualgroup"})
            //        }
            //        self.tabs = tabs

            self.tabs = tabs
        }
    }
}

struct DetailTabContainer_Previews: PreviewProvider {
    static var previews: some View {
        DetailTabContainer()
    }
}
