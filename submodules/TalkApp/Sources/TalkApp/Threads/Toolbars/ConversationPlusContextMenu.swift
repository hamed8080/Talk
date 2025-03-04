//
//  ConversationPlusContextMenu.swift
//  Talk
//
//  Created by hamed on 11/3/23.
//

import SwiftUI
import TalkViewModels
import TalkUI
import Chat
import TalkModels

struct ConversationPlusContextMenu: View {
    @EnvironmentObject var threadsVM: ThreadsViewModel
    @EnvironmentObject var builderVM: ConversationBuilderViewModel
    @EnvironmentObject var appstate: AppState
    @State private var showCreateConversationSheet = false

    var body: some View {
        HStack(spacing: 6) {
            conversationBuilderDialogButton
            logo
            ConnectionStatusToolbar()
        }
        .padding(.horizontal, 8)
        .sheet(isPresented: $showCreateConversationSheet, onDismiss: onDismissBuilder) {
            StartThreadContactPickerView()
        }
    }

    private var isLargeSize: Bool {
        let mode = UIApplication.shared.windowMode()
        if mode == .ipadFullScreen || mode == .ipadHalfSplitView || mode == .ipadTwoThirdSplitView {
            return true
        } else {
            return false
        }
    }

    private func onDismissBuilder() {
        Task {
            await builderVM.clear()
        }
    }

    private var conversationBuilderDialogButton: some View {
        ToolbarButtonItem(imageName: "plus", hint: "ThreadList.Toolbar.startNewChat", padding: 12) {
            withAnimation {
                AppState.shared.objectsContainer.searchVM.searchText = ""
                AppState.shared.objectsContainer.contactsVM.searchContactString = ""
                NotificationCenter.cancelSearch.post(name: .cancelSearch, object: true)
                showCreateConversationSheet.toggle()
            }
        }
        .frame(minWidth: 0, maxWidth: ToolbarButtonItem.buttonWidth, minHeight: 0, maxHeight: 38)
        .clipped()
        .foregroundStyle(Color.App.toolbarButton)
    }

    @ViewBuilder
    private var logo: some View {
        let image = Language.isRTL ? "talk_logo_text" : "talk_logo_text_en"
        Image(image)
            .resizable()
            .scaledToFit()
            .frame(height: 12)
            .foregroundStyle(Color.App.toolbarButton)
            .offset(x: -8)
    }
}

struct ConversationPlusContextMenu_Previews: PreviewProvider {
    static var previews: some View {
        ConversationPlusContextMenu()
            .environmentObject(ThreadsViewModel())
            .environmentObject(ContactsViewModel())
    }
}
