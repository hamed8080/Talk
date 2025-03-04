//
//  SyncView.swift
//  Talk
//
//  Created by hamed on 9/10/23.
//

import Chat
import SwiftUI

struct SyncView: View {
    @AppStorage("sync_contacts") var isSynced = false
    @AppStorage("cloesd") var closed = false

    var body: some View {
        if !isSynced, !closed {
            VStack {
                HStack {
                    Button {
                        withAnimation {
                            closed = true
                        }
                    } label: {
                        Label("", systemImage: "xmark")
                            .foregroundColor(.gray)
                    }
                    .frame(width: 24, height: 24)
                    .offset(x: 0, y: -28)

                    VStack(alignment: .leading) {
                        Text("Contacts.Sync.contacts")
                            .font(.fSubtitle)
                        Text("Contacts.Sync.subtitle")
                            .font(.fCaption2)
                            .foregroundStyle(.gray)
                    }
                    Spacer()
                }

                Button {
                    withAnimation {
                        isSynced = true
                        Task { @ChatGlobalActor in
                            ChatManager.activeInstance?.contact.sync()
                        }
                    }
                } label: {
                    Text("Contacts.Sync.sync")
                        .foregroundColor(Color.App.accent)
                        .font(.fBoldTitle)
                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 36)
                }
                .padding(4)
                .buttonStyle(.bordered)
            }
            .padding(16)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius:(24)))
        }
    }
}

struct SyncView_Previews: PreviewProvider {
    static var previews: some View {
        SyncView()
    }
}
