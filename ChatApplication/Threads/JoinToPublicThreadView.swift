//
//  JoinToPublicThreadView.swift
//  ChatApplication
//
//  Created by hamed on 5/16/23.
//

import Chat
import ChatAppUI
import Combine
import Foundation
import SwiftUI

struct JoinToPublicThreadView: View {
    @State private var publicThreadName: String = ""
    @State private var cancelables = Set<AnyCancellable>()
    @State private var isThreadExist: Bool = false
    var onCompeletion: (String) -> Void

    var body: some View {
        NavigationView {
            Form {
                SectionTitleView(title: "Join")
                SectionImageView(image: Image("link"))

                Section {
                    TextField("Enter name of the chat...", text: $publicThreadName)
                        .textFieldStyle(.roundedBorder)
                } footer: {
                    if !isThreadExist, !publicThreadName.isEmpty {
                        Text("The thread name is not exist!")
                            .foregroundColor(.red)
                    } else {
                        Text("Join to a public thread by it's unique name.")
                    }
                }
                .listRowBackground(Color.clear)

                Section {
                    Button {
                        onCompeletion(publicThreadName)
                    } label: {
                        Label("Join".uppercased(), systemImage: "door.right.hand.open")
                            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 36)
                    }
                    .opacity(isThreadExist ? 1.0 : 0.5)
                    .disabled(!isThreadExist)
                    .font(.iransansSubheadline)
                    .buttonStyle(.bordered)
                }
                .listRowBackground(Color.clear)
            }
        }
        .animation(.easeInOut, value: isThreadExist)
        .onAppear {
            NotificationCenter.default.publisher(for: .thread)
                .sink { event in
                    switch event.object as? ThreadEventTypes {
                    case let .isNameAvailable(response):
                        isThreadExist = response.result == nil
                    default:
                        break
                    }
                }
                .store(in: &cancelables)

            NotificationCenter.default.publisher(for: .system)
                .sink { event in
                    switch event.object as? SystemEventTypes {
                    case let .error(response):
                        if response.error?.code == 130 {
                            isThreadExist = true
                        }
                    default:
                        break
                    }
                }
                .store(in: &cancelables)
        }
        .onChange(of: publicThreadName) { newValue in
            ChatManager.activeInstance?.conversation.isNameAvailable(.init(name: newValue))
        }
    }
}

struct JoinToPublicThreadView_Previews: PreviewProvider {
    static var previews: some View {
        JoinToPublicThreadView { _ in }
    }
}
