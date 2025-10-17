//
//  UploadsManagerListView.swift
//  TalkApp
//
//  Created by Hamed Hosseini on 7/9/25.
//

import SwiftUI
import TalkViewModels
import Chat
import TalkUI

public struct UploadsManagerListView: View {
    @EnvironmentObject var uploadsManager: UploadsManager
    @State private var pausedAll: Bool = false
    
    public var body: some View {
        List {
            ForEach(uploadsManager.elements) { element in
                UploadElementRow(element: element, paused: element.viewModel.state == .paused)
                    .environmentObject(element.viewModel)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            onCancelTapped(element)
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
        .animation(.easeInOut, value: uploadsManager.elements.count)
        .safeAreaInset(edge: .top, spacing: 0) { toolbar }
    }
    
    private var toolbar: some View {
        ToolbarView(searchId: "UploadsManager",
                    title: "\("UploadsManager.title".bundleLocalized())",
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
                uploadsManager.resumeAll()
                pausedAll = false
            } else {
                uploadsManager.pauseAll()
                pausedAll = true
            }
        } label: {
            Image(systemName: pausedAll ? "play" : "pause")
               .resizable()
               .scaledToFit()
               .padding(12)
               .font(.fBoldBody)
               .foregroundStyle(Color.App.toolbarButton)
       }
       .buttonStyle(.borderless)
       .frame(minWidth: 0, minHeight: 0, maxHeight: 38)
       .clipped()
       .disabled(uploadsManager.elements.isEmpty)
       .opacity(uploadsManager.elements.isEmpty ? 0.5 : 1.0)
    }
    
    private var terminateAllButton: some View {
        Button {
            uploadsManager.cancelAll()
        } label: {
           Image(systemName: "xmark")
               .resizable()
               .scaledToFit()
               .padding(12)
               .font(.fBoldBody)
               .foregroundStyle(Color.App.toolbarButton)
       }
       .buttonStyle(.borderless)
       .frame(minWidth: 0, minHeight: 0, maxHeight: 38)
       .clipped()
       .disabled(uploadsManager.elements.isEmpty)
       .opacity(uploadsManager.elements.isEmpty ? 0.5 : 1.0)
    }
    
    private func onCancelTapped(_ element: UploadManagerElement) {
        uploadsManager.cancel(element: element, userCanceled: true)
    }
}

fileprivate struct UploadElementRow: View {
    @EnvironmentObject var viewModel: UploadFileViewModel
    let element: UploadManagerElement
    @State var paused: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(viewModel.fileNameString)
                    .font(.fBody)
                    .foregroundStyle(Color.App.textPrimary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                if element.isInQueue {
                    Text("UploadsManager.inUploadingQueue")
                        .foregroundColor(Color.App.textSecondary)
                        .font(.fCaption3)
                }
            }
            
            Spacer()
            VStack(alignment: .trailing) {
                uploadButton
                Text(viewModel.fileSizeString)
                    .foregroundColor(Color.App.textSecondary)
                    .font(.fCaption3)
            }
        }
        .environment(\.layoutDirection, Language.isRTL ? .rightToLeft : .leftToRight)
        .contentShape(Rectangle())
        .listRowBackground(Color.App.bgPrimary)
        .onTapGesture {
            if viewModel.state == .paused {
                AppState.shared.objectsContainer.uploadsManager.resume(element: element)
            } else {
                AppState.shared.objectsContainer.uploadsManager.pause(element: element)
            }
        }
        .onChange(of: viewModel.state) { newValue in
            paused = newValue == .paused
        }
    }
    
    private var uploadButton: some View {
        ZStack {
            Image(systemName: stateIcon)
                .resizable()
                .scaledToFit()
                .frame(width: 12, height: 12)
                .foregroundStyle(Color.App.white)
            
            Circle()
                .trim(from: 0.0, to: min(Double(percent) / 100, 1.0))
                .stroke(style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                .foregroundColor(Color.App.white)
                .rotationEffect(Angle(degrees: 270))
                .frame(width: 28, height: 28)
                .rotateAnimtion(pause: $paused)
                .environment(\.layoutDirection, .leftToRight)
        }
        .frame(width: 36, height: 36)
        .background(Color.App.accent)
        .clipShape(RoundedRectangle(cornerRadius:(36 / 2)))
    }
    
    var percent: Int64 { viewModel.uploadPercent }
    
    var stateIcon: String {
        if viewModel.state == .uploading {
            return "pause.fill"
        } else if viewModel.state == .paused {
            return "play.fill"
        } else {
            return "arrow.up"
        }
    }
}
