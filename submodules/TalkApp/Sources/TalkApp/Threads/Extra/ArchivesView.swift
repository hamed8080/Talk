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
        List(viewModel.archives) { thread in
            ThreadRow() {
                AppState.shared.objectsContainer.navVM.append(thread: thread.toStruct())
            }
            .environmentObject(thread)
            .listRowInsets(.init(top: 16, leading: 8, bottom: 16, trailing: 8))
            .listRowSeparatorTint(Color.App.dividerSecondary)
            .listRowBackground(Color.App.bgPrimary)
            .onAppear {
                if self.viewModel.archives.last == thread {
                    viewModel.loadMore()
                }
            }
        }
        .background(Color.App.bgPrimary)
        .listEmptyBackgroundColor(show: viewModel.archives.isEmpty)
        .overlay(alignment: .bottom) {
            ListLoadingView(isLoading: $viewModel.isLoading)
        }
        .overlay(alignment: .top) {
            if viewModel.archives.isEmpty && !viewModel.isLoading {
                Text("ArchivedTab.empty".bundleLocalized())
                    .foregroundStyle(Color.App.textPlaceholder)
            }
        }
        .animation(.easeInOut, value: viewModel.archives.count)
        .animation(.easeInOut, value: viewModel.isLoading)
        .listStyle(.plain)
        .normalToolbarView(title: "Tab.archives", type: ArchivesNavigationValue.self)       
    }
}

struct ArchivesView_Previews: PreviewProvider {
    static var previews: some View {
        ArchivesView()
    }
}
