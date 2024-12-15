//
//  SelectedContact.swift
//  Talk
//
//  Created by hamed on 11/6/23.
//

import SwiftUI
import TalkViewModels
import TalkUI
import Chat

struct SelectedContact: View {
    let viewModel: ContactsViewModel
    let contact: Contact
    @State var isSelectedToDelete: Bool = false

    var body: some View {
        HStack {
            removeButton
            userImage
            userName
        }
        .padding(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
        .background(isSelectedToDelete ?  Color.App.accent : Color.App.textSecondary)
        .clipShape(RoundedRectangle(cornerRadius:(12)))
        .animation(.easeInOut, value: isSelectedToDelete)
        .onTapGesture {
            isSelectedToDelete.toggle()
        }
    }

    @ViewBuilder var removeButton: some View {
        if isSelectedToDelete {
            Button {
                viewModel.toggleSelectedContact(contact: contact)
            } label: {
                Image(systemName: "xmark")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                    .foregroundStyle(Color.App.white)
                    .contentShape(Rectangle())
            }
        }
    }

   @ViewBuilder var userImage: some View {
        if !isSelectedToDelete {
            ImageLoaderView(contact: contact, font: .iransansBoldCaption2)
                .id("\(contact.image ?? "")\(contact.id ?? 0)")
                .foregroundColor(Color.App.textPrimary)
                .frame(width: 22, height: 22)
                .background(Color.App.color1.opacity(0.4))
                .clipShape(RoundedRectangle(cornerRadius:(14)))
        }
    }

    var userName: some View {
        Text(verbatim: "\(contact.firstName ?? "") \(contact.lastName ?? "")")
            .lineLimit(1)
            .font(.iransansSubheadline)
            .foregroundColor(isSelectedToDelete ? Color.App.white : Color.App.textPrimary)
    }
}

struct SelectedContact_Previews: PreviewProvider {
    static var previews: some View {
        SelectedContact(viewModel: .init(), contact: .init(firstName: "John", id: 1, lastName: "Doe"))
    }
}
