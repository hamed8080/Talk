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
        let description = viewModel.thread?.description.validateString ?? "General.noDescription".bundleLocalized()
        SectionRowContainer(key: "General.description", value: description, lineLimit: nil)
    }
}

struct DetailThreadDescriptionSection_Previews: PreviewProvider {
    static var previews: some View {
        DetailThreadDescriptionSection()
    }
}
