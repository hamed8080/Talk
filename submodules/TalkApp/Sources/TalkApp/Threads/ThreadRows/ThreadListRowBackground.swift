//
//  ThreadListRowBackground.swift
//  Talk
//
//  Created by hamed on 12/5/23.
//

import SwiftUI
import TalkViewModels
import Chat
import TalkModels

struct ThreadListRowBackground: View {
    @EnvironmentObject var thread: CalculatedConversation

    var body: some View {
        thread.isSelected ? Color.App.bgChatSelected :
        thread.pin == true ? Color.App.bgSecondary :
        Color.App.bgPrimary
    }
}

struct ThreadListRowBackground_Previews: PreviewProvider {
    static var previews: some View {
        ThreadListRowBackground()
            .environmentObject(CalculatedConversation(id: 1))
    }
}
