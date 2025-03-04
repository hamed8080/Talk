//
//  ThreadsSheetFactoryView.swift
//  Talk
//
//  Created by hamed on 6/28/23.
//

import Foundation
import SwiftUI
import TalkModels
import TalkViewModels

struct ThreadsSheetFactoryView: View {
    @EnvironmentObject var viewModel: ThreadsViewModel
    @EnvironmentObject var container: ObjectsContainer

    var body: some View {
        switch viewModel.sheetType {
        case .tagManagement:
            AddThreadToTagsView(viewModel: container.tagsVM) { tag in
                container.tagsVM.addThreadToTag(tag: tag, threadId: viewModel.selectedThraed?.id)
                viewModel.sheetType = nil
            }
        case .addParticipant:
            AddParticipantsToThreadView() { contacts in
                Task { @MainActor in
                    await viewModel.addParticipantsToThread(contacts)
                    viewModel.sheetType = nil
                }
            }
        case .none:
            Text("Not implemented a sheet type!")
        }
    }
}
