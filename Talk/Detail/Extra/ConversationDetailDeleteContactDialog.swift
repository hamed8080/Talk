//
//  ConversationDetailDeleteContactDialog.swift
//  Talk
//
//  Created by hamed on 2/20/24.
//

import SwiftUI
import TalkViewModels
import TalkUI
import TalkModels
import Chat

struct ConversationDetailDeleteContactDialog: View {
    let participant: Participant
    @EnvironmentObject var viewModel: ContactsViewModel

    var body: some View {
        VStack(alignment: .trailing, spacing: 16) {
            Text(attributedString)
                .foregroundStyle(Color.App.textPrimary)
                .font(.fSubheadline)
                .multilineTextAlignment(.leading)
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)

            HStack {
                Button {
                    withAnimation {
                        viewModel.delete(.init(id: participant.contactId))
                        AppState.shared.objectsContainer.appOverlayVM.dialogView = nil
                    }
                } label: {
                    Text("General.delete")
                        .foregroundStyle(Color.App.accent)
                        .font(.fBody)
                        .frame(minWidth: 48, minHeight: 48)
                        .fontWeight(.medium)
                }

                Button {
                    withAnimation {
                        AppState.shared.objectsContainer.appOverlayVM.dialogView = nil
                    }
                } label: {
                    Text("General.cancel")
                        .foregroundStyle(Color.App.textPlaceholder)
                        .font(.fBody)
                        .frame(minWidth: 48, minHeight: 48)
                        .fontWeight(.medium)
                }
            }
        }
        .frame(maxWidth: 320)
        .padding(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
        .background(MixMaterialBackground())
    }

    private var attributedString: AttributedString {
        let key = String(localized: .init("ConversationDetail.deleteContact"), bundle: Language.preferedBundle)
        let contactName = participant.contactName ?? participant.name ?? ""
        let string = String(format: key, contactName)
        let attr = NSMutableAttributedString(string: string)
        let range = (attr.string as NSString).range(of: contactName)
        attr.addAttributes([NSAttributedString.Key.foregroundColor: UIColor(named: "accent")!], range: range)
        return AttributedString(attr)
    }
}

struct ConversationDetailDeleteContactDialog_Previews: PreviewProvider {
    static var previews: some View {
        ConversationDetailDeleteContactDialog(participant: .init(id: 1))
            .environmentObject(ContactsViewModel())
    }
}
