//
//  ConversationTopSafeAreaInset.swift
//  Talk
//
//  Created by hamed on 11/11/23.
//

import SwiftUI
import TalkViewModels
import TalkUI
import TalkModels

struct ConversationTopSafeAreaInset: View {
    @EnvironmentObject var threadsVM: ThreadsViewModel
    private var container: ObjectsContainer { AppState.shared.objectsContainer }
    @State private var isInSearchMode: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            ToolbarView(
                searchId: "Tab.chats",
                title: "",
                leadingViews: ConversationPlusContextMenu(),
                centerViews: EmptyView(),
                trailingViews: searchButton
            )
            ThreadListSearchBarFilterView(isInSearchMode: $isInSearchMode)
                .background(MixMaterialBackground())
                .environmentObject(container.searchVM)
            if AppState.isInSlimMode {
                AudioPlayerView()
            }
            ThreadSearchView()
                .environmentObject(container.searchVM)

            if threadsVM.threads.count == 0, threadsVM.firstSuccessResponse, AppState.isInSlimMode {
                NothingHasBeenSelectedView(contactsVM: container.contactsVM)
            }
        }
        .onReceive(NotificationCenter.cancelSearch.publisher(for: .cancelSearch)) { newValue in
            if let cancelSearch = newValue.object as? Bool, cancelSearch == true, cancelSearch && isInSearchMode {
                isInSearchMode.toggle()
            }
        }
    }

    @ViewBuilder var searchButton: some View {
        if isInSearchMode {
            Button {
                Task {
                    await container.searchVM.closedSearchUI()
                    await MainActor.run {
                        withAnimation {
                            isInSearchMode.toggle()
                        }
                    }
                }
            } label: {
                Image(systemName: "xmark")
                    .resizable()
                    .scaledToFit()
                    .padding(12)
                    .font(.fBody)
                    .foregroundStyle(Color.App.toolbarButton)
            }
            .buttonStyle(.borderless)
            .frame(minWidth: 0, minHeight: 0, maxHeight: isInSearchMode ? 38 : 0)
            .clipped()
        } else {
            ToolbarButtonItem(imageName: "magnifyingglass", hint: "Search", padding: 10) {
                withAnimation {
                    isInSearchMode.toggle()
                }
            }
            .frame(minWidth: 0, maxWidth: isInSearchMode ? 0 : ToolbarButtonItem.buttonWidth, minHeight: 0, maxHeight: isInSearchMode ? 0 : 38)
            .clipped()
            .foregroundStyle(Color.App.toolbarButton)
        }
    }
}

struct ConversationTopSafeAreaInset_Previews: PreviewProvider {
    static var previews: some View {
        ConversationTopSafeAreaInset()
    }
}
