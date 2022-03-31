//
//  ContactRow.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import SwiftUI
import FanapPodChatSDK

struct ContactRow: View {
    
    private (set) var contact:Contact
    
    @State
    private var isSelected   = false
    
    @Binding
    public var isInEditMode:Bool
    
    public var viewModel:ContactsViewModel
    
    @State
    public var showActionViews:Bool = false
    
    var callState:CallState = CallState.shared
    
    var body: some View {
        VStack{
            VStack{
                HStack(spacing: 0, content: {
                    if isInEditMode{
                        Image(systemName: isSelected ? "checkmark.circle" : "circle")
                            .font(.title)
                            .frame(width: 22, height: 22, alignment: .center)
                            .foregroundColor(Color.blue)
                            .padding(24)
                            .onTapGesture {
                                isSelected.toggle()
                                viewModel.toggleSelectedContact(contact ,isSelected)
                            }
                    }
                    Avatar(url:contact.image ?? contact.linkedUser?.image ,userName: contact.firstName?.uppercased(), fileMetaData: nil)
                    
                    VStack(alignment: .leading, spacing:8){
                        Text("\(contact.firstName ?? "") \(contact.lastName ?? "")")
                            .padding(.leading , 16)
                            .lineLimit(1)
                            .font(.headline)
                        if let notSeenDuration = ContactRow.getDate(notSeenDuration: contact.notSeenDuration){
                            Text(notSeenDuration)
                                .padding(.leading , 16)
                                .font(.headline.weight(.medium))
                                .foregroundColor(Color.gray)
                        }
                    }
                    Spacer()
                    if contact.blocked  == true{
                        Text("Blocked")
                            .font(.headline.weight(.medium))
                            .padding(4)
                            .foregroundColor(Color.red)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color.red)
                            )
                    }
                })
                if showActionViews{
                    getActionsView()
                }else{
                    EmptyView()
                        .customAnimation(.default)
                }
            }
            .modifier(AnimatingCellHeight(height: self.showActionViews ? 148 : 64))
            .padding(SwiftUI.EdgeInsets(top: 16, leading: 8, bottom: 16, trailing: 8))
            .background(Color.primary.opacity(0.08))
            .cornerRadius(16)
            
        }
        .onTapGesture {
            withAnimation {
                showActionViews.toggle()
            }
        }
    }
    
    
    @ViewBuilder
    func getActionsView()->some View{
        Divider()
        HStack{
            
            ActionButton(iconSfSymbolName: "message",taped:{
                viewModel.createThread(invitees: [Invitee(id: "\(contact.id ?? 0)", idType: .TO_BE_USER_CONTACT_ID)])
            })
            
            ActionButton(iconSfSymbolName: "video",height: 16,taped:{
                callState.model.setIsVideoCallRequest(true)
                callState.model.setIsP2PCalling(true)
                callState.model.setSelectedContacts([contact])
                withAnimation(.spring()){
                    callState.model.setShowCallView(true)
                }
            })
            
            ActionButton(iconSfSymbolName: "phone", taped:{
                callState.model.setIsP2PCalling(true)
                callState.model.setSelectedContacts([contact])
                withAnimation(.spring()){
                    callState.model.setShowCallView(true)
                }
            })
            
            ActionButton(iconSfSymbolName: "hand.raised.slash", iconColor: contact.blocked == true ? .red : .blue , taped:{
                viewModel.blockOrUnBlock(contact)
            })
        }
    }
    
    static func getDate(notSeenDuration:Int?) -> String?{
        if let notSeenDuration = notSeenDuration{
            let milisecondIntervalDate = Date().millisecondsSince1970 - Int64(notSeenDuration)
            return Date(milliseconds:milisecondIntervalDate).timeAgoSinceDate()
        }else{
            return nil
        }
    }
}

struct ActionButton: View{
    
    var iconSfSymbolName :String
    var height           :CGFloat      = 22
    var iconColor        :Color = .blue
    var taped            :(()->Void)?
    
    var body: some View{
        Button(action: {
            taped?()
        }, label: {
            Image(systemName: iconSfSymbolName)
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: height)
                .foregroundColor(iconColor)
        })
        .buttonStyle(BorderlessButtonStyle())//don't remove this line click happen in all veiws
        .padding(16)
    }
}

struct ContactRow_Previews: PreviewProvider {
    @State static var isInEditMode = false
    static var contact:Contact{
        let contact = Contact(blocked: false, cellphoneNumber: "+98 9369161601", email: nil, firstName: "Hamed", hasUser: true, id: 0, image: "http://www.careerbased.com/themes/comb/img/avatar/default-avatar-male_14.png", lastName: "Hosseini", linkedUser: nil, notSeenDuration: 1622969881, timeStamp: nil, userId: nil)
        return contact
    }
    
    static var previews: some View {
        Group {
            ContactRow(contact: contact, isInEditMode: $isInEditMode,viewModel: ContactsViewModel())
                .preferredColorScheme(.dark)
        }
    }
}
