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
    @State private var isDownloading: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            ToolbarView(
                searchId: "Tab.chats",
                title: "",
                leadingViews: ConversationPlusContextMenu(),
                centerViews: EmptyView(),
                trailingViews: trainlingViews
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
        }.onReceive(AppState.shared.objectsContainer.downloadsManager.$elements) { newValue in
            isDownloading = newValue.count > 0
        }
    }
    
    
    private var trainlingViews: some View {
        HStack {
            compatibleDownladsManagerButton
            searchButton
        }
    }
    
    @ViewBuilder
    private var compatibleDownladsManagerButton: some View {
        if #available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *) {
            iOS17AnimatedDownloadButton
        } else {
            downloadsManagerButton
        }
    }
    
    @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
    private var iOS17AnimatedDownloadButton: some View {
        downloadsManagerButton
            .symbolEffect(.pulse)
    }
    
    private var downloadsManagerButton: some View {
        NavigationLink {
            DownloadsManagerListView()
                .environmentObject(AppState.shared.objectsContainer.downloadsManager)
        } label: {
            Image(systemName: "arrow.down.circle.dotted")
                .resizable()
                .scaledToFit()
                .padding(8)
                .frame(minWidth: 0, maxWidth: isDownloading ? ToolbarButtonItem.buttonWidth : 0, minHeight: 0, maxHeight: isDownloading ? 38 : 0)
                .accessibilityHint("Download")
                .fontWeight(.medium)
                .clipped()
                .foregroundStyle(Color.App.toolbarButton)
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
