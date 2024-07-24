//
//  ContactRow.swift
//  Talk
//
//  Created by Hamed Hosseini on 5/27/21.
//

import AdditiveUI
import Chat
import SwiftUI
import TalkUI
import TalkViewModels

struct ContactRow: View {
    let contact: Contact
    @Binding public var isInSelectionMode: Bool
    var contactImageURL: String? { contact.image ?? contact.user?.image }
    private var searchVM: ThreadsSearchViewModel { AppState.shared.objectsContainer.searchVM }

    var body: some View {
        VStack {
            HStack(spacing: 0) {
                ContactRowRadioButton(contact: contact)
                    .padding(.trailing, isInSelectionMode ? 8 : 0)
                let config = ImageLoaderConfig(url: contact.image ?? contact.user?.image ?? "", userName: String.splitedCharacter(contact.firstName ?? ""))
                ImageLoaderView(imageLoader: .init(config: config), textFont: .fBoldBody)
                    .id("\(contact.image ?? "")\(contact.id ?? 0)")
                    .font(.fBody)
                    .foregroundColor(Color.App.white)
                    .frame(width: 52, height: 52)
                    .background(Color(uiColor: String.getMaterialColorByCharCode(str: contact.firstName ?? "")))
                    .clipShape(RoundedRectangle(cornerRadius:(22)))

                VStack(alignment: .leading, spacing: 2) {
                    if searchVM.isInSearchMode {
                        Text(searchVM.attributdTitle(for: "\(contact.firstName ?? "") \(contact.lastName ?? "")"))
                            .padding(.leading, 16)
                            .foregroundColor(Color.App.textPrimary)
                            .lineLimit(1)
                            .font(.fSubheadline)
                            .fontWeight(.semibold)
                    } else {
                        Text(verbatim: "\(contact.firstName ?? "") \(contact.lastName ?? "")")
                            .padding(.leading, 16)
                            .foregroundColor(Color.App.textPrimary)
                            .lineLimit(1)
                            .font(.fSubheadline)
                            .fontWeight(.semibold)
                    }
//                    if let notSeenDuration = contact.notSeenDuration?.localFormattedTime {
//                        let lastVisitedLabel = String(localized: .init("Contacts.lastVisited"))
//                        let time = String(format: lastVisitedLabel, notSeenDuration)
//                        Text(time)
//                            .padding(.leading, 16)
//                            .font(.fBody)
//                            .foregroundColor(Color.App.textSecondary)
//                    }
                    notFoundUserText
                }
                Spacer()
                if contact.blocked == true {
                    Text("General.blocked")
                        .font(.fCaption2)
                        .foregroundColor(Color.App.red)
                        .padding(.trailing, 4)
                }
            }
        }
        .contentShape(Rectangle())
        .animation(.easeInOut, value: contact.blocked)
        .animation(.easeInOut, value: contact)
    }

    var isOnline: Bool {
        contact.notSeenDuration ?? 16000 < 15000
    }

    @ViewBuilder
    private var notFoundUserText: some View {
        if contact.hasUser == false || contact.hasUser == nil {
            Text("Contctas.list.notFound")
                .foregroundStyle(Color.App.accent)
                .font(.fCaption2)
                .fontWeight(.medium)
                .padding(.leading, 16)
        }
    }
}

struct ContactRowRadioButton: View {
    let contact: Contact
    @EnvironmentObject var viewModel: ContactsViewModel

    var body: some View {
        let isSelected = viewModel.isSelected(contact: contact)
        RadioButton(visible: $viewModel.isInSelectionMode, isSelected: .constant(isSelected)) { isSelected in
            viewModel.toggleSelectedContact(contact: contact)
        }
    }
}

struct ContactRow_Previews: PreviewProvider {
    @State static var isInSelectionMode = false

    static var previews: some View {
        Group {
            ContactRow(contact: MockData.contact, isInSelectionMode: $isInSelectionMode)
                .environmentObject(ContactsViewModel())
                .preferredColorScheme(.dark)
        }
    }
}
