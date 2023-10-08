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
                        closed = true
                    } label: {
                        Label("", systemImage: "xmark")
                            .foregroundColor(.gray)
                    }
                    .frame(width: 24, height: 24)
                    .offset(x: 0, y: -28)

                    VStack(alignment: .leading) {
                        Text("Contacts.Sync.contacts")
                            .font(.iransansSubtitle)
                        Text("Contacts.Sync.subtitle")
                            .font(.iransansCaption2)
                            .foregroundStyle(.gray)
                    }
                    Spacer()
                }

                Button {
                    isSynced = true
                    ChatManager.activeInstance?.contact.sync()
                } label: {
                    Text("Contacts.Sync.sync")
                        .foregroundColor(Color.main)
                        .font(.iransansBoldTitle)
                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 36)
                }
                .padding(4)
                .buttonStyle(.bordered)
            }
            .padding(16)
            .background(.ultraThinMaterial)
            .cornerRadius(24)
        }
    }
}

struct SyncView_Previews: PreviewProvider {
    static var previews: some View {
        SyncView()
    }
}
