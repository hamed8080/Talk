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
            let typeKey = type == .normal ? "General.contact" : type?.isChannelType == true ? "Thread.channel" : "Thread.group"
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
            if let viewModel = viewModel.threadVM {
                ThreadSearchList(threadVM: viewModel)
                    .environmentObject(viewModel.searchedMessagesViewModel)
            }
        }
    }
}

struct DetailToolbarContainer_Previews: PreviewProvider {
    static var previews: some View {
        DetailToolbarContainer()
    }
}
