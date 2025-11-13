//
//  MutualsTabView.swift
//  Talk
//
//  Created by hamed on 3/26/23.
//

import SwiftUI
import TalkViewModels
import TalkUI
import Chat

struct MutualsTabView: View {
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
                            Task {
                                try await goToConversation(thread)
                            }
                        }
                }
            }

            if viewModel.lazyList.isLoading {
                DetailLoading()
            }

            if viewModel.mutualThreads.isEmpty && !viewModel.lazyList.isLoading {
                EmptyResultViewInTabs()
            }
        }
    }
    
    /// We have to refetch the conversation because it is not a complete instance of Conversation in mutual response.
    /// So things like admin, public link, and ... don't have any values.
    private func goToConversation(_ conversation: Conversation) async throws {
      
        guard
            let id = conversation.id,
            let serverConversation = try await GetThreadsReuqester().get(.init(threadIds: [id])).first
        else { return }
        AppState.shared.objectsContainer.navVM.createAndAppend(conversation: serverConversation)
    }
}

struct MutualThreadRow: View {
    var thread: Conversation

    init(thread: Conversation) {
        self.thread = thread
    }

    var body: some View {
        HStack {
            ImageLoaderView(conversation: thread)
                .id("\(thread.computedImageURL ?? "")\(thread.id ?? 0)")
                .font(.fSubtitle)
                .foregroundColor(.white)
                .frame(width: 36, height: 36)
                .background(Color(uiColor: String.getMaterialColorByCharCode(str: thread.title ?? "")))
                .clipShape(RoundedRectangle(cornerRadius:(18)))
            Text(thread.computedTitle)
                .font(.fSubheadline)
                .lineLimit(1)
            Spacer()
        }
        .contentShape(Rectangle())
        .padding(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
    }
}

struct MutualThreadsView_Previews: PreviewProvider {
    static var previews: some View {
        MutualsTabView()
    }
}
