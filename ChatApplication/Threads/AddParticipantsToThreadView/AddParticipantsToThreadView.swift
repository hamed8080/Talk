//
//  AddParticipantsToThreadView.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 6/5/21.
//

import SwiftUI
import FanapPodChatSDK

struct AddParticipantsToThreadView:View {
    
    @StateObject
    var viewModel:AddParticipantsToViewModel
    
    @StateObject
    var contactsVM = ContactsViewModel()
    
    @EnvironmentObject var appState:AppState
    
    @State var title    :String  = "Invite"
    
    var onCompleted:([Contact])->()
    
    var body: some View{
        VStack(alignment:.leading,spacing: 0){
            List {
                ForEach(contactsVM.model.contacts , id:\.id) { contact in
                    StartThreadContactRow(contact: contact, isInMultiSelectMode: .constant(true), viewModel: contactsVM)
                        .onAppear {
                            if contactsVM.model.contacts.last == contact{
                                contactsVM.loadMore()
                            }
                        }
                }
            }
            .listStyle(.plain)
        }
        .padding(0)
    }
    
    func getTrailingItems()->[NavBarItem]{
        return [NavBarButton(title: "Add", isBold: true) {
            withAnimation {
                onCompleted(contactsVM.model.selectedContacts)
            }
        }.getNavBarItem()]
    }
}

struct StartThreadResultModel_Previews: PreviewProvider {
    static var previews: some View {
        let appState = AppState.shared
        let vm = StartThreadContactPickerViewModel()
        let contactVM = ContactsViewModel()
        StartThreadContactPickerView(viewModel: vm,contactsVM: contactVM, onCompletedConfigCreateThread: { model in
        })
        .preferredColorScheme(.dark)
            .onAppear(){
                vm.setupPreview()
                contactVM.setupPreview()
            }
            .environmentObject(appState)
    }
}
