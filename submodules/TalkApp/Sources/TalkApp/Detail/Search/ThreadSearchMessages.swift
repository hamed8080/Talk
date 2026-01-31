//
//  ThreadSearchMessages.swift
//  Talk
//
//  Created by hamed on 3/13/23.
//

import SwiftUI
import TalkUI
import TalkViewModels
import Chat
import Lottie

struct ThreadSearchMessages: View {
    let threadVM: ThreadViewModel
    @EnvironmentObject var viewModel: ThreadSearchMessagesViewModel
    @Environment(\.colorScheme) var colorScheme
    @FocusState private var searchFocus: Field?
    @Environment(\.dismiss) var dismiss
    enum Field: Hashable {
        case search
    }

    var body: some View {
        ZStack {
            if viewModel.searchedMessages.count > 0 {
                ScrollView {
                    LazyVStack {
                        ForEach(viewModel.searchedMessages) { message in
                            SearchMessageRow(message: message, threadVM: threadVM) {
                                onTap(message: message)
                            }
                            .onAppear {
                                if message == viewModel.searchedMessages.last {
                                    viewModel.loadMore()
                                }
                            }
                        }
                    }
                }
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                .transition(.asymmetric(insertion: .move(edge: .top), removal: .move(edge: .bottom)))
                .background(Color.App.bgPrimary.ignoresSafeArea())
                .environment(\.layoutDirection, .leftToRight)
            } else {
                ZStack {
                    if viewModel.isLoading {
                        LottieView(animation: .named(viewModel.searchedMessages.isEmpty ? "talk_logo_animation.json" : "dots_loading.json"))
                            .playing()
                            .defaultColor()
                            .frame(height: 52)
                    } else if !viewModel.searchText.isEmpty && !viewModel.isLoading {
                        Text("General.nothingFound")
                            .font(Font.normal(.title))
                    }
                }
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                .background(Color.App.bgPrimary.ignoresSafeArea())
                .transition(.opacity)
            }
        }
        .environment(\.layoutDirection, Language.isRTL ? .rightToLeft : .leftToRight)
        .environment(\.colorScheme, isDarkMode ? .dark : .light)
        .safeAreaInset(edge: .top) {
            searchViewToolbar
                .environment(\.layoutDirection, Language.isRTL ? .rightToLeft : .leftToRight)
                .environment(\.colorScheme, isDarkMode ? .dark : .light)
        }
        .onAppear {
            searchFocus = .search
        }
    }
    
    @ViewBuilder var searchViewToolbar: some View {
        HStack(spacing: 0) {
            searchTextField
            closeSearchButton
        }
        .frame(minWidth: 0, maxWidth: .infinity)
        .padding(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
        .background(MixMaterialBackground(color: Color.App.bgToolbar).ignoresSafeArea())
    }
    
    private var isDarkMode: Bool {
        AppSettingsModel.restore().isDarkMode 
    }
    
    private func onTap(message: Message) {
        dismiss()
        threadVM.historyVM.cancelTasks()
        let task: Task<Void, any Error> = Task { @MainActor in
            if let time = message.time, let messageId = message.id {
                threadVM.scrollVM.disableExcessiveLoading()
                await threadVM.historyVM.moveToTime(time, messageId)
                viewModel.cancel()
            }
        }
        threadVM.historyVM.setTask(task)
    }
    
    private var searchTextField: some View {
        TextField("General.searchHere".bundleLocalized(), text: $viewModel.searchText)
            .font(Font.normal(.body))
            .textFieldStyle(.clear)
            .focused($searchFocus, equals: .search)
            .frame(maxHeight: 38)
            .clipped()
            .background {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.clear)
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
    }
    
    private var closeSearchButton: some View {
        Button {
            dismiss()
            viewModel.cancel()
        } label: {
            Image(systemName: "xmark")
                .resizable()
                .padding(12)
                .scaledToFit()
                .font(Font.normal(.body))
                .foregroundStyle(Color.App.toolbarButton)
        }
        .buttonStyle(.borderless)
        .frame(maxHeight: 42)
        .contentShape(Rectangle())
        .clipped()
    }
}
