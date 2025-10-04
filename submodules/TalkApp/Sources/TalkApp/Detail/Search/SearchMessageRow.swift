//
//  SearchMessageRow.swift
//  Talk
//
//  Created by hamed on 6/21/22.
//

import Chat
import SwiftUI
import TalkUI
import TalkViewModels
import TalkModels

struct SearchMessageRow: View {
    let message: Message
    let threadVM: ThreadViewModel?
    let onTap: () -> Void
    @Environment(\.dismiss) var dismiss

    var body: some View {
        Button {
            onTap()
        } label: {
            HStack(alignment: .top) {
                
                Text(message.message ?? "")
                    .font(.fBody)
                    .multilineTextAlignment(.leading)
                    .foregroundStyle(Color.App.textPrimary)
                    .lineLimit(1)
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    if let name = message.participant?.name {
                        Text(name)
                            .foregroundStyle(Color.App.textSecondary)
                            .lineLimit(1)
                            .font(Font.fCaption2)
                    }
                    
                    if let timeString = message.time?.date.localFormattedTime {
                        Text(timeString)
                            .foregroundStyle(Color.App.textSecondary)
                            .font(Font.fCaption2)
                    }
                }
            }
            .environment(\.layoutDirection, Language.isRTL ? .rightToLeft : .leftToRight)
            .padding()
        }
    }
}

struct SearchMessageRow_Previews: PreviewProvider {
    static var previews: some View {
        SearchMessageRow(message: .init(id: 1), threadVM: .init(thread: .init(id: 1))) {
            
        }
    }
}
