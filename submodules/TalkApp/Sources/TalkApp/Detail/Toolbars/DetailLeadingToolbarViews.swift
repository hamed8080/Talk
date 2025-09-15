//
//  DetailLeadingToolbarViews.swift
//  Talk
//
//  Created by hamed on 5/6/24.
//

import SwiftUI
import TalkViewModels

struct DetailLeadingToolbarViews: View {
    @EnvironmentObject var viewModel: ThreadDetailViewModel
    
    var body: some View {
        NavigationBackButton(automaticDismiss: false) {
            viewModel.dismissByBackButton()
        }
    }
}

struct DetailLeadingToolbarViews_Previews: PreviewProvider {
    static var previews: some View {
        DetailLeadingToolbarViews()
    }
}
