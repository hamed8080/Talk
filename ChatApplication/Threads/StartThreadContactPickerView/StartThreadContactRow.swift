//
//  StartThreadContactRow.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import FanapPodChatSDK
import SwiftUI

struct StartThreadContactRow: View {
    @State private var isSelected = false
    @Binding public var isInMultiSelectMode: Bool
    @EnvironmentObject var viewModel: ContactsViewModel
    var contact: Contact
    @StateObject var imageLoader = ImageLoader()

    var body: some View {
        VStack {
            VStack {
                HStack(spacing: 0, content: {
                    if isInMultiSelectMode {
                        Image(systemName: isSelected ? "checkmark.circle" : "circle")
                            .font(.title3)
                            .frame(width: 16, height: 16, alignment: .center)
                            .foregroundColor(Color.blue)
                            .padding(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                            .onTapGesture {
                                isSelected.toggle()
                                viewModel.toggleSelectedContact(contact: contact)
                            }
                    }

                    imageLoader.imageView
                        .font(.system(size: 16).weight(.heavy))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(Color.blue.opacity(0.4))
                        .cornerRadius(16)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("\(contact.firstName ?? "") \(contact.lastName ?? "")")
                            .padding(.leading, 16)
                            .lineLimit(1)
                            .font(.subheadline)
                        if let notSeenDuration = getDate(contact: contact) {
                            Text(notSeenDuration)
                                .padding(.leading, 16)
                                .font(.caption2.weight(.medium))
                                .foregroundColor(Color.gray)
                        }
                    }
                    Spacer()
                    if contact.blocked == true {
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
            }
        }
        .animation(.spring(), value: isInMultiSelectMode)
        .animation(.easeInOut, value: isSelected)
        .contentShape(Rectangle())
        .onAppear {
            imageLoader.fetch(url: contact.image ?? contact.user?.image, userName: contact.firstName)
        }
    }

    func getDate(contact: Contact) -> String? {
        if let notSeenDuration = contact.notSeenDuration {
            let milisecondIntervalDate = Date().millisecondsSince1970 - Int64(notSeenDuration)
            return Date(milliseconds: milisecondIntervalDate).timeAgoSinceDate()
        } else {
            return nil
        }
    }
}

struct StartThreadContactRow_Previews: PreviewProvider {
    @State static var isInMultiSelectMode = true
    static var previews: some View {
        Group {
            StartThreadContactRow(isInMultiSelectMode: $isInMultiSelectMode, contact: MockData.contact)
                .environmentObject(ContactsViewModel())
                .preferredColorScheme(.dark)
        }
    }
}
