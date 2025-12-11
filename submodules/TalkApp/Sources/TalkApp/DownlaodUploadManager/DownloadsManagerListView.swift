//
//  DownloadsManagerListView.swift
//  TalkApp
//
//  Created by Hamed Hosseini on 7/9/25.
//

import SwiftUI
import TalkViewModels
import Chat
import TalkUI

public struct DownloadsManagerListView: View {
    @EnvironmentObject var downloadManager: DownloadsManager
    @State private var pausedAll: Bool = false
    
    public var body: some View {
        List {
            ForEach(downloadManager.elements) { element in
                DownloadElementRow(element: element)
                    .environmentObject(element.viewModel)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            showCancel(element)
                        } label: {
                            Label("", systemImage: "xmark.circle")
                        }
                    }
            }
        }
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
        .environment(\.layoutDirection, Language.isRTL ? .rightToLeft : .leftToRight)
        .listStyle(.plain)
        .environment(\.defaultMinListRowHeight, 0)
        .background(Color.App.bgPrimary)
        .animation(.easeInOut, value: downloadManager.elements.count)
        .safeAreaInset(edge: .top, spacing: 0) { toolbar }
    }
    
    private var toolbar: some View {
        ToolbarView(searchId: "DownalodsManager",
                    title: "\("DownalodsManager.title".bundleLocalized())",
                    showSearchButton: false,
                    searchPlaceholder: nil,
                    searchKeyboardType: .default,
                    leadingViews: leadingView,
                    centerViews: EmptyView(),
                    trailingViews: trailingItems) { searchValue in
        }
    }
    
    private var leadingView: some View {
        NavigationBackButton(automaticDismiss: false) {
            AppState.shared.objectsContainer.navVM.removeUIKit()
        }
    }
    
    private var trailingItems: some View {
        HStack {
            pauseAllButton
            terminateAllButton
        }
    }
    
    private var pauseAllButton: some View {
        Button {
            if pausedAll {
                downloadManager.resumeAll()
                pausedAll = false
            } else {
                downloadManager.pauseAll()
                pausedAll = true
            }
        } label: {
            Image(systemName: pausedAll ? "play" : "pause")
               .resizable()
               .scaledToFit()
               .padding(12)
               .font(Font.bold(.body))
               .foregroundStyle(Color.App.toolbarButton)
       }
       .buttonStyle(.borderless)
       .frame(minWidth: 0, minHeight: 0, maxHeight: 38)
       .clipped()
       .disabled(downloadManager.elements.isEmpty)
       .opacity(downloadManager.elements.isEmpty ? 0.5 : 1.0)
    }
    
    private var terminateAllButton: some View {
        Button {
            downloadManager.cancelAll()
        } label: {
           Image(systemName: "xmark")
               .resizable()
               .scaledToFit()
               .padding(12)
               .font(Font.bold(.body))
               .foregroundStyle(Color.App.toolbarButton)
       }
       .buttonStyle(.borderless)
       .frame(minWidth: 0, minHeight: 0, maxHeight: 38)
       .clipped()
       .disabled(downloadManager.elements.isEmpty)
       .opacity(downloadManager.elements.isEmpty ? 0.5 : 1.0)
    }
    
    private func showCancel(_ element: DownloadManagerElement) {
        downloadManager.cancel(element: element)
    }
}

fileprivate struct DownloadElementRow: View {
    @EnvironmentObject var viewModel: DownloadFileViewModel
    @State var paused: Bool = false
    @State var metadata: FileMetaData?
    let element: DownloadManagerElement
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(metadata?.name ?? viewModel.message.messageTitle)
                    .font(Font.normal(.body))
                    .foregroundStyle(Color.App.textPrimary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                if element.isInQueue {
                    Text("DownalodsManager.inDownloadingQueue")
                        .foregroundColor(Color.App.textSecondary)
                        .font(Font.normal(.caption3))
                }
            }
            
            Spacer()
            VStack(alignment: .trailing) {
                downloadButton
                Text(metadata?.file?.size?.toSizeStringShort(locale: Language.preferredLocale) ?? "")
                    .foregroundColor(Color.App.textSecondary)
                    .font(Font.normal(.caption3))
            }
        }
        .environment(\.layoutDirection, Language.isRTL ? .rightToLeft : .leftToRight)
        .contentShape(Rectangle())
        .listRowBackground(Color.App.bgPrimary)
        .task { @AppBackgroundActor in
            let metadata = await viewModel.message.fileMetaData
            await MainActor.run {
                self.metadata = metadata
            }
        }
        .onTapGesture {
            if viewModel.state == .paused {
                AppState.shared.objectsContainer.downloadsManager.resume(element: element)
            } else {
                AppState.shared.objectsContainer.downloadsManager.pause(element: element)
            }
        }
        .onChange(of: viewModel.state) { newValue in
            paused = newValue == .paused
        }
    }
    
    private var downloadButton: some View {
        ZStack {
            Image(systemName: stateIcon)
                .resizable()
                .scaledToFit()
                .frame(width: 12, height: 12)
                .foregroundStyle(Color.App.white)
            
            Circle()
                .trim(from: 0.0, to: min(Double(percent) / 100, 1.0))
                .stroke(style: StrokeStyle(lineWidth: 4.0, lineCap: .round, lineJoin: .round))
                .foregroundColor(Color.App.textPrimary)
                .rotationEffect(Angle(degrees: 270))
                .frame(width: 36, height: 36)
                .rotateAnimtion(pause: $paused)
                .environment(\.layoutDirection, .leftToRight)
        }
        .frame(width: 36, height: 36)
        .background(Color.App.accent)
        .clipShape(RoundedRectangle(cornerRadius:(36 / 2)))
    }
    
    var percent: Int64 { viewModel.downloadPercent }
    
    var stateIcon: String {
        if viewModel.state == .downloading {
            return "pause.fill"
        } else if viewModel.state == .paused {
            return "play.fill"
        } else {
            return "arrow.down"
        }
    }
}
