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
            Task { @MainActor in
                viewModel.threadVM?.scrollVM.disableExcessiveLoading()
                AppState.shared.objectsContainer.contactsVM.editContact = nil
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    AppState.shared.objectsContainer.threadDetailVM.clear()
                }
                AppState.shared.objectsContainer.navVM.removeDetail()
            }
        }
    }
}

struct DetailLeadingToolbarViews_Previews: PreviewProvider {
    static var previews: some View {
        DetailLeadingToolbarViews()
    }
}
