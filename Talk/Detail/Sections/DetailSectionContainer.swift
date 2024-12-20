//
//  DetailSectionContainer.swift
//  Talk
//
//  Created by hamed on 5/6/24.
//

import SwiftUI
import TalkViewModels
import TalkUI

struct DetailSectionContainer: View {
    @EnvironmentObject var viewModel: ThreadDetailViewModel

    var body: some View {
        VStack {
            if let threadVM = viewModel.threadVM {
                DetailInfoViewSection(viewModel: viewModel, threadVM: threadVM)
                    .environmentObject(AppState.shared.objectsContainer.appOverlayVM) // for click on thread image
            }
            if let participantViewModel = viewModel.participantDetailViewModel {
                DetailCellPhoneNumberSection()
                    .environmentObject(participantViewModel)
                DetailUserNameSection()
                    .environmentObject(participantViewModel)
            }
            DetailPublicLinkSection()
            DetailThreadDescriptionSection()
            DetailTopButtonsSection()
                .padding([.top, .bottom])
            StickyHeaderSection(header: "", height: 10)
        }
    }
}

struct DetailSectionContainer_Previews: PreviewProvider {
    static var previews: some View {
        DetailSectionContainer()
    }
}
