//
//  GroupCallSelectionContentList.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import SwiftUI

struct GroupCallSelectionContentList: View {
    @StateObject var viewModel: CallsHistoryViewModel
    @State var isInSelectionMode: Bool = true
    @StateObject var contactViewModel: ContactsViewModel = .init()
    @EnvironmentObject var callViewModel: CallViewModel
    @State var groupTitle: String = ""

    var body: some View {
        GeometryReader { reader in
            ZStack {
//                VStack(spacing: 0) {
//                    List {
//                        MultilineTextField("Group Name ...", text: $groupTitle, backgroundColor: Color.gray.opacity(0.2)) { _ in
//                            hideKeyboard()
//                        }
//                        .cornerRadius(16)
//                        .noSeparators()
//
//                        ForEach(contactViewModel.contacts, id: \.id) { contact in
//                            ContactRow(isInSelectionMode: $isInSelectionMode, contact: contact)
//                                .noSeparators()
//                                .onAppear {
//                                    if contactViewModel.contacts.last == contact {
//                                        viewModel.loadMore()
//                                    }
//                                }
//                        }
//                        .onDelete(perform: contactViewModel.delete)
//                    }
//                    .listStyle(.plain)
                }

                VStack {
//                    GeometryReader { reader in
//                        LoadingViewAt(isLoading: viewModel.isLoading, reader: reader)
//                    }
                }
//            }
        }
        .navigationBarTitle(Text("Select Contacts"), displayMode: .inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
//                Button {
//                    callViewModel.startCall(contacts: contactViewModel.selectedContacts, isVideoOn: true, groupName: groupTitle)
//                } label: {
//                    Label {
//                        Text("VIDEO")
//                    } icon: {
//                        Image(systemName: "video.fill")
//                    }
//                }
//
//                Button {
//                    callViewModel.startCall(contacts: contactViewModel.selectedContacts, isVideoOn: false, groupName: groupTitle)
//                } label: {
//                    Label {
//                        Text("VOICE")
//                    } icon: {
//                        Image(systemName: "phone.fill")
//                    }
//                }
            }
        }
    }

    @ViewBuilder
    func callButton(title: String, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)

            Text(title.uppercased())
                .font(.system(size: 16).bold())
        }
    }
}

struct GroupCallSelectionContentListView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = CallsHistoryViewModel()
        GroupCallSelectionContentList(viewModel: viewModel)
    }
}
