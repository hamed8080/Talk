//
//  AddParticipantsToThreadView.swift
//  Talk
//
//  Created by Hamed Hosseini on 6/5/21.
//

import Chat
import SwiftUI
import TalkViewModels
import TalkUI
import TalkModels

struct AddParticipantsToThreadView: View {
    @EnvironmentObject var contactsVM: ContactsViewModel
    var onCompleted: (ContiguousArray<Contact>) -> Void

    var body: some View {
        List {
            searchedContacts
            normalContacts
        }
        .listStyle(.plain)
        .animation(.easeInOut, value: contactsVM.contacts.count)
        .animation(.easeInOut, value: contactsVM.searchedContacts.count)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            submitButton
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            topView
        }
        .onAppear {
            /// We use ContactRowContainer view because it is essential to force the ineer contactRow View to show radio buttons.
            contactsVM.isInSelectionMode = true
        }
        .onDisappear {
            contactsVM.searchContactString = ""
            contactsVM.isInSelectionMode = false
        }
    }

    @ViewBuilder private var searchedContacts: some View {
        if !contactsVM.searchedContacts.isEmpty {
            ForEach(contactsVM.searchedContacts) { contact in
                ContactRowContainer(contact: .constant(contact), isSearchRow: true, enableSwipeAction: false)
            }
        }
    }

    @ViewBuilder private var normalContacts: some View {
        if contactsVM.searchedContacts.isEmpty {
            ForEach(contactsVM.contacts) { contact in
                ContactRowContainer(contact: .constant(contact), isSearchRow: false, enableSwipeAction: false)
                    .onAppear {
                        Task {
                            if contactsVM.contacts.last == contact {
                                await contactsVM.loadMore()
                            }
                        }
                    }
            }
        }
    }

    private var submitButton: some View {
        SubmitBottomButton(text: "General.add", enableButton: .constant(contactsVM.selectedContacts.count > 0), isLoading: .constant(false)) {
            onCompleted(contactsVM.selectedContacts)
            contactsVM.deselectContacts() // to clear for the next time
        }
    }

    private var topView: some View {
        VStack(alignment: .leading, spacing: 0) {
            TextField("General.searchHere".bundleLocalized(), text: $contactsVM.searchContactString)
                .frame(height: 48)
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .submitLabel(.done)
                .font(.normal(.body))

            Spacer()
            Text("General.add")
                .frame(height: 30)
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .background(Color.App.dividerSecondary)
                .foregroundStyle(Color.App.textSecondary)
                .font(.normal(.body))
        }
        .frame(height: 78)
        .background(.ultraThinMaterial)
    }
}

struct StartThreadResultModel_Previews: PreviewProvider {
    static var previews: some View {
        AddParticipantsToThreadView() { _ in
        }
        .environmentObject(ContactsViewModel())
        .preferredColorScheme(.dark)
    }
}
