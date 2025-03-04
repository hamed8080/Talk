//
//  MutualThreadsView.swift
//  Talk
//
//  Created by hamed on 3/26/23.
//

import SwiftUI
import TalkViewModels
import TalkUI

struct MutualThreadsView: View {
    @EnvironmentObject var viewModel: MutualGroupViewModel

    var body: some View {
        LazyVStack {
            ThreadTabDetailStickyHeaderSection(header: "", height:  4)
            if !viewModel.mutualThreads.isEmpty {
                ForEach(viewModel.mutualThreads) { thread in
                    MutualThreadRow(thread: thread)
                        .padding(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 0))
                        .onAppear {
                            if thread.id == viewModel.mutualThreads.last?.id {
                                Task {
                                    await viewModel.loadMoreMutualGroups()
                                }
                            }
                        }
                        .onTapGesture {
                            AppState.shared.showThread(thread)
                        }
                }
            }

            if viewModel.lazyList.isLoading {
                LoadingView()
                    .id(UUID())
                    .frame(width: 22, height: 22)
            }

            if viewModel.mutualThreads.isEmpty && !viewModel.lazyList.isLoading {
                EmptyResultViewInTabs()
            }
        }
    }
}

struct MutualThreadsView_Previews: PreviewProvider {
    static var previews: some View {
        MutualThreadsView()
    }
}
