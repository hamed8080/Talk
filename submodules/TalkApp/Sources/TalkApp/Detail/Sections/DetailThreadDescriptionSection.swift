//
//  DetailThreadDescriptionSection.swift
//  Talk
//
//  Created by hamed on 5/6/24.
//

import SwiftUI
import TalkViewModels

struct DetailThreadDescriptionSection: View {
    @EnvironmentObject var viewModel: ThreadDetailViewModel

    var body: some View {
        /// P2P thread partner bio
        let partnerBio = viewModel.participantDetailViewModel?.participant.chatProfileVO?.bio ?? "General.noDescription".bundleLocalized()
        
        /// Group thread description
        let groupDescription = viewModel.thread?.description.validateString ?? "General.noDescription".bundleLocalized()
        
        let isGroup = viewModel.thread?.group == true
        
        let key = isGroup ? "General.description" : "Settings.bio"
        
        let value = isGroup ? groupDescription : partnerBio
        
        SectionRowContainer(key: key, value: value, lineLimit: nil)
    }
}

struct DetailThreadDescriptionSection_Previews: PreviewProvider {
    static var previews: some View {
        DetailThreadDescriptionSection()
    }
}
