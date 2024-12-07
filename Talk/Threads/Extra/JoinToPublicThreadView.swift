//
//  JoinToPublicThreadView.swift
//  Talk
//
//  Created by hamed on 5/16/23.
//

import Chat
import Combine
import Foundation
import SwiftUI
import TalkUI
import TalkModels

struct JoinToPublicThreadView: View {
    @State private var publicThreadName: String = ""
    @State private var isThreadExist: Bool = false
    var onCompeletion: (String) -> Void

    var body: some View {
        NavigationView {
            Form {
                SectionTitleView(title: "Thread.Join.title")
                SectionImageView(image: Image("link"))

                Section {
                    TextField("Thread.Join.enterThreadNameHere".bundleLocalized(), text: $publicThreadName)
                        .frame(minHeight: 36)
                        .textFieldStyle(.customBorderedWith(minHeight: 36, cornerRadius: 12))

                } footer: {
                    if !isThreadExist, !publicThreadName.isEmpty {
                        Text("Thread.Join.duplicateName")
                            .foregroundColor(.red)
                    } else {
                        Text("Thread.Join.footer")
                    }
                }
                .listRowBackground(Color.clear)

                Section {
                    Button {
                        onCompeletion(publicThreadName)
                    } label: {
                        Label("Thread.Join.title", systemImage: "door.right.hand.open")
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
        .onReceive(NotificationCenter.thread.publisher(for: .thread)) { event in
            switch event.object as? ThreadEventTypes {
            case let .isNameAvailable(response):
                isThreadExist = response.result == nil
            default:
                break
            }
        }
        .onReceive(NotificationCenter.system.publisher(for: .system)) { event in
            switch event.object as? SystemEventTypes {
            case let .error(response):
                if response.error?.code == 130 {
                    isThreadExist = true
                }
            default:
                break
            }
        }
        .onChange(of: publicThreadName) { newValue in
            Task { @ChatGlobalActor in
                ChatManager.activeInstance?.conversation.isNameAvailable(.init(name: newValue))
            }
        }
    }
}

struct JoinToPublicThreadView_Previews: PreviewProvider {
    static var previews: some View {
        JoinToPublicThreadView { _ in }
    }
}
