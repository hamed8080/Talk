//
//  CreateDirectThreadView.swift
//  Talk
//
//  Created by hamed on 5/16/23.
//

import Chat
import Combine
import SwiftUI
import TalkExtensions
import TalkUI
import TalkViewModels
import TalkModels

struct CreateDirectThreadView: View {
    @State private var type: InviteeTypes = .cellphoneNumber
    @State private var message: String = ""
    @State private var id: String = ""
    var onCompeletion: (Invitee, String) -> Void
    @State var types = InviteeTypes.allCases.filter { $0 != .unknown }

    var body: some View {
        NavigationView {
            Form {
                SectionTitleView(title: "ThreadList.Toolbar.fastMessage")
                SectionImageView(image: Image("fast_message"))

                Section {
                    Picker("Contact type", selection: $type) {
                        ForEach(types) { value in
                            Text(value.title)
                                .foregroundColor(.primary)
                        }
                    }
                    .pickerStyle(.navigationLink)
                    let typeString = type.title.bundleLocalized()
                    let fastMessge = "Thread.enterFastMessageType".bundleLocalized()
                    TextField(String(format: fastMessge, typeString).bundleLocalized(), text: $id)
                        .keyboardType(type == .cellphoneNumber ? .phonePad : .default)

                    TextField("Thread.SendContainer.typeMessageHere".bundleLocalized(), text: $message)
                } footer: {
                    Text("Thread.fastMessageFooter")
                }

                Button {
                    onCompeletion(Invitee(id: id, idType: type), message)
                } label: {
                    Label("General.send", systemImage: "paperplane")
                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 36)
                }
                .font(.fSubheadline)
            }
        }
    }
}

struct CreateDirectThreadView_Previews: PreviewProvider {
    static var previews: some View {
        CreateDirectThreadView { _, _ in }
    }
}
