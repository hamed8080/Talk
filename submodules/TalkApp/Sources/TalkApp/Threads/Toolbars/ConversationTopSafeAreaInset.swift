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
    @State private var item: AVAudioPlayerItem?
    @State private var isDownloading: Bool = false
    @State private var isUploading: Bool = false
    @State private var isFilternewMessagesOn = false

    var body: some View {
        VStack(spacing: 0) {
            ToolbarView(
                searchId: "Tab.chats",
                title: "",
                leadingViews: ConversationPlusContextMenu(),
                centerViews: EmptyView(),
                trailingViews: trainlingViews
            )
            ThreadListSearchBarFilterView(isInSearchMode: $isInSearchMode, isFilternewMessagesOn: $isFilternewMessagesOn)
                .background(MixMaterialBackground())
                .environmentObject(container.searchVM)
            if let item = item {
                NavigationPlayerWrapper()
                    .padding(0)
                    .frame(height: ToolbarButtonItem.buttonWidth)
                    .frame(maxWidth: .infinity)
                    .environment(\.layoutDirection, Language.isRTL ? .rightToLeft : .leftToRight)
                    .background(MixMaterialBackground())
                    .onReceive(NotificationCenter.default.publisher(for: Notification.Name("CLOSE_PLAYER"))) { _ in
                        self.item = nil
                    }
                    .onReceive(item.$isFinished) { isFinished in
                        if isFinished {
                            self.item = nil
                        }
                    }
            }
            ThreadSearchView()
                .environmentObject(container.searchVM)

            if threadsVM.threads.count == 0, threadsVM.firstSuccessResponse, AppState.isInSlimMode {
                NothingHasBeenSelectedView(contactsVM: container.contactsVM)
            }
        }
        .animation(.easeInOut, value: item == nil)
        .onReceive(NotificationCenter.cancelSearch.publisher(for: .cancelSearch)) { newValue in
            if let cancelSearch = newValue.object as? Bool, cancelSearch == true, cancelSearch && isInSearchMode {
                isInSearchMode.toggle()
            }
            
            /// Reset filter new messages on close by x mark
            if !isInSearchMode {
                isFilternewMessagesOn = false
            }
        }.onReceive(AppState.shared.objectsContainer.downloadsManager.$elements) { newValue in
            isDownloading = newValue.count > 0
        }
        .onReceive(AppState.shared.objectsContainer.uploadsManager.$elements) { newValue in
            isUploading = newValue.count > 0
        }
    }
    
    private var trainlingViews: some View {
        HStack {
            compatibleDownladsManagerButton
            compatibleUploadsManagerButton
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
            Image(systemName: downloadIconNameCompatible)
                .resizable()
                .scaledToFit()
                .padding(14)
                .frame(minWidth: 0, maxWidth: isDownloading ? ToolbarButtonItem.buttonWidth : 0, minHeight: 0, maxHeight: isDownloading ? ToolbarButtonItem.buttonWidth : 0)
                .accessibilityHint("Download")
                .fontWeight(.medium)
                .contentShape(Rectangle())
                .clipped()
                .foregroundStyle(Color.App.toolbarButton)
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("SWAP_PLAYER"))) { notif in
            if let item = notif.object as? AVAudioPlayerItem {
                self.item = item
            }
        }
    }
    
    @ViewBuilder
    private var compatibleUploadsManagerButton: some View {
        if #available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *) {
            iOS17AnimatedUploadButton
        } else {
            uploadsManagerButton
        }
    }
    
    @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
    private var iOS17AnimatedUploadButton: some View {
        uploadsManagerButton
            .symbolEffect(.pulse)
    }
    
    private var uploadsManagerButton: some View {
        NavigationLink {
            UploadsManagerListView()
                .environmentObject(AppState.shared.objectsContainer.uploadsManager)
        } label: {
            Image(systemName: uploadIconNameCompatible)
                .resizable()
                .scaledToFit()
                .padding(14)
                .frame(minWidth: 0, maxWidth: isUploading ? ToolbarButtonItem.buttonWidth : 0, minHeight: 0, maxHeight: isUploading ? ToolbarButtonItem.buttonWidth : 0)
                .accessibilityHint("Upload")
                .fontWeight(.medium)
                .contentShape(Rectangle())
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
                            
                            /// Reset filter new messages on close by x mark
                            if !isInSearchMode {
                                isFilternewMessagesOn = false
                            }
                        }
                    }
                }
            } label: {
                Image(systemName: "xmark")
                    .resizable()
                    .scaledToFit()
                    .padding(14)
                    .font(.fBody)
                    .foregroundStyle(Color.App.toolbarButton)
            }
            .buttonStyle(.borderless)
            .frame(minWidth: isInSearchMode ? 0 : ToolbarButtonItem.buttonWidth, minHeight: 0, maxHeight: isInSearchMode ? ToolbarButtonItem.buttonWidth : 0)
            .contentShape(Rectangle())
            .clipped()
        } else {
            ToolbarButtonItem(imageName: "magnifyingglass", hint: "Search", padding: 14) {
                withAnimation {
                    isInSearchMode.toggle()
                }
            }
            .frame(minWidth: 0, maxWidth: isInSearchMode ? 0 : ToolbarButtonItem.buttonWidth, minHeight: 0, maxHeight: isInSearchMode ? 0 : ToolbarButtonItem.buttonWidth)
            .contentShape(Rectangle())
            .clipped()
            .foregroundStyle(Color.App.toolbarButton)
        }
    }
    
    private var downloadIconNameCompatible: String {
        if #available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, *) {
            return "arrow.down.circle.dotted"
        }
        return "arrow.down.circle"
    }
    
    private var uploadIconNameCompatible: String {
        if #available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, *) {
            return "arrow.up.circle.dotted"
        }
        return "arrow.up.circle"
    }
}

struct ConversationTopSafeAreaInset_Previews: PreviewProvider {
    static var previews: some View {
        ConversationTopSafeAreaInset()
    }
}
