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
    let viewModel: ThreadsViewModel

    var body: some View {
        ArchivesTableViewControllerWrapper(viewModel: viewModel)
            .background(Color.App.bgPrimary)
            .ignoresSafeArea()
            .normalToolbarView(title: "Tab.archives", type: String.self)
            .onAppear {
                Task {
                    await viewModel.getThreads()
                }
            }
    }
}

struct ArchivesView_Previews: PreviewProvider {
    static var previews: some View {
        ArchivesView(viewModel: .init(isArchive: true))
    }
}
