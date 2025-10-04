//
//  DetailToolbarContainer.swift
//  Talk
//
//  Created by hamed on 5/6/24.
//

import SwiftUI
import TalkViewModels

struct DetailToolbarContainer: View {
    @EnvironmentObject var viewModel: ThreadDetailViewModel

    var body: some View {
        VStack(spacing: 0) {
            let type = viewModel.thread?.type
            let isChannel = type?.isChannelType == true
            let isGroup = type == .channelGroup || type == .ownerGroup || type == .publicGroup || viewModel.thread?.group == true && !isChannel
            let typeKey = isGroup ? "Thread.group" : isChannel ? "Thread.channel" : "General.contact"
            ToolbarView(searchId: "DetailView",
                        title: "\("General.info".bundleLocalized()) \(typeKey.bundleLocalized())",
                        showSearchButton: false,
                        searchPlaceholder: "General.searchHere",
                        searchKeyboardType: .default,
                        leadingViews: DetailLeadingToolbarViews(),
                        centerViews: EmptyView(),
                        trailingViews: DetailTarilingToolbarViews()) { searchValue in
                viewModel.threadVM?.searchedMessagesViewModel.searchText = searchValue
            }
        }
    }
}

struct DetailToolbarContainer_Previews: PreviewProvider {
    static var previews: some View {
        DetailToolbarContainer()
    }
}
