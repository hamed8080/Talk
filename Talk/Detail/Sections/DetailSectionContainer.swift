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
            DetailInfoViewSection(viewModel: viewModel)
            if let participantViewModel = viewModel.participantDetailViewModel {
                DetailUserNameSection()
                    .environmentObject(participantViewModel)
                DetailCellPhoneNumberSection()
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
