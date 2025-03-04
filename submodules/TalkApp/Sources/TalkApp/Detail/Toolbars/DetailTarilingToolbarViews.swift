//
//  DetailTarilingToolbarViews.swift
//  Talk
//
//  Created by hamed on 5/6/24.
//

import SwiftUI
import TalkViewModels

struct DetailTarilingToolbarViews: View {
    @EnvironmentObject var viewModel: ThreadDetailViewModel

    var body: some View {
        if viewModel.canShowEditConversationButton == true {
            DetailEditConversationButton()
        } else if let viewModel = viewModel.participantDetailViewModel {
            DetailEditContactButton()
                .environmentObject(viewModel)
        }
    }
}

struct DetailTarilingEditConversation_Previews: PreviewProvider {
    static var previews: some View {
        DetailTarilingToolbarViews()
    }
}
