//
//  SearchMessageRow.swift
//  Talk
//
//  Created by hamed on 6/21/22.
//

import Chat
import SwiftUI
import TalkUI
import TalkViewModels
import TalkModels

struct SearchMessageRow: View {
    let message: Message
    let threadVM: ThreadViewModel?

    var body: some View {
        Button {
            onTap()
        } label: {
            HStack {
                VStack(alignment: .leading) {
                    Text(message.message ?? "")
                        .font(.iransansBody)
                        .multilineTextAlignment(.leading)
                        .foregroundStyle(Color.App.textPrimary)
                        .lineLimit(1)
                    HStack {
                        if let timeString = message.time?.date.localFormattedTime {
                            Text(timeString)
                                .foregroundStyle(Color.App.textSecondary)
                        }
                        Spacer()
                        if let name = message.participant?.name {
                            Text(name)
                                .foregroundStyle(Color.App.textSecondary)
                                .lineLimit(1)
                        }
                    }
                }
                Spacer()
            }
            .environment(\.layoutDirection, Language.isRTL ? .rightToLeft : .leftToRight)
            .padding()
        }
    }

    private func onTap() {
        Task { @MainActor in
            if let time = message.time, let messageId = message.id {
                AppState.shared.objectsContainer.threadDetailVM.clear()
                AppState.shared.appStateNavigationModel.userToCreateThread = nil
                AppState.shared.objectsContainer.navVM.remove(innerBack: true)
                threadVM?.scrollVM.disableExcessiveLoading()
                await threadVM?.historyVM.moveToTime(time, messageId)
                threadVM?.searchedMessagesViewModel.cancel()
            }
        }
    }
}

struct SearchMessageRow_Previews: PreviewProvider {
    static var previews: some View {
        SearchMessageRow(message: .init(id: 1), threadVM: .init(thread: .init(id: 1)))        
    }
}
