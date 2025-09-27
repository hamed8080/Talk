//
//  ArchivesView.swift
//  Talk
//
//  Created by hamed on 10/29/23.
//

import SwiftUI
import TalkViewModels
import TalkUI
import TalkExtensions

struct ArchivesView: View {
    @EnvironmentObject var viewModel: ArchiveThreadsViewModel

    var body: some View {
        ArchivesTableViewControllerWrapper(viewModel: viewModel)
            .background(Color.App.bgPrimary)
            .normalToolbarView(title: "Tab.archives", type: ArchivesNavigationValue.self)
            .onAppear {
                Task {
                    await viewModel.getArchivedThreads()
                }
            }
    }
}

struct ArchivesView_Previews: PreviewProvider {
    static var previews: some View {
        ArchivesView()
    }
}
