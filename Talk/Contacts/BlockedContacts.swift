//
//  BlockedContacts.swift
//  Talk
//
//  Created by hamed on 6/11/23.
//

import Chat
import SwiftUI
import TalkViewModels
import TalkUI

struct BlockedContacts: View {
    @EnvironmentObject var viewModel: ContactsViewModel

    var body: some View {
        List(viewModel.blockedContacts, id: \.blockId) { blocked in
            HStack {
                let userId = blocked.contact?.cellphoneNumber ?? blocked.contact?.email ?? "\(blocked.coreUserId ?? 0)"
                
                ImageLoaderView(blocked: blocked)
                    .id(userId)
                    .font(.iransansBody)
                    .foregroundColor(.white)
                    .frame(width: 52, height: 52)
                    .background(Color.App.color1.opacity(0.4))
                    .clipShape(RoundedRectangle(cornerRadius:(22)))

                let contactName = blocked.contact?.user?.name ?? blocked.contact?.firstName
                let name = contactName ?? blocked.nickName
                VStack(alignment: .leading) {
                    Text(name ?? "")
                        .foregroundStyle(Color.App.textPrimary)
                        .font(.iransansBoldBody)

                    Text(userId)
                        .font(.caption2)
                        .foregroundStyle(Color.App.textSecondary)
                }

                Spacer()
                Button {
                    if let blockedId = blocked.blockId {
                        viewModel.unblock(blockedId)
                    }
                } label: {
                    Image(systemName: "xmark.circle")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                }
            }
            .listRowBackground(Color.App.bgPrimary)
            .listRowSeparatorTint(blocked.blockId == viewModel.blockedContacts.last?.blockId ? Color.clear : Color.App.dividerPrimary)
        }
        .background(Color.App.bgPrimary)
        .listStyle(.plain)
        .normalToolbarView(title: "Contacts.blockedList", type: BlockedContactsNavigationValue.self)
    }
}

struct BlockedContacts_Previews: PreviewProvider {
    static var previews: some View {
        BlockedContacts()
    }
}
