//
//  DetailView.swift
//  Talk
//
//  Created by Hamed Hosseini on 6/5/21.
//

import SwiftUI
import TalkViewModels
import TalkModels

struct ThreadDetailView: View {
    @EnvironmentObject var viewModel: ThreadDetailViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var viewWidth: CGFloat = 0

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical) {
                VStack(spacing: 0) {
                    DetailSectionContainer()
                        .id("DetailSectionContainer")
                    
                    DetailTabContainer(maxWidth: viewWidth)
                        .id("DetailTabContainer")
                }
                .frame(maxWidth: viewWidth == 0 ? .infinity : viewWidth)
            }
            .onAppear {
                viewModel.scrollViewProxy = proxy
            }
        }
        .navigationBarBackButtonHidden(true)
        .background(Color.App.bgPrimary)
        .environmentObject(viewModel)
        .background(frameReader)
        .safeAreaInset(edge: .top, spacing: 0) { DetailToolbarContainer() }
        .background(DetailAddOrEditContactSheetView())
        .onReceive(viewModel.$dismiss) { newValue in
            if newValue {
                prepareToDismiss()
            }
        }
        .onDisappear {
            Task(priority: .background) {
                viewModel.threadVM?.searchedMessagesViewModel.reset()
            }
            
            /// We make sure user is not moving to edit thread detail or contact
            if AppState.shared.objectsContainer.navVM.presntedNavigationLinkId == nil {
                viewModel.threadVM?.participantsViewModel.clear()
            }
        }
    }

    private func prepareToDismiss() {
        AppState.shared.objectsContainer.navVM.remove(innerBack: false)
        AppState.shared.objectsContainer.navVM.popLastDetail()
        AppState.shared.appStateNavigationModel.userToCreateThread = nil
        dismiss()
    }
    
    private var frameReader: some View {
        GeometryReader { reader in
            Color.clear.onAppear {
                if viewWidth == 0 {
                    self.viewWidth = reader.size.width
                }
            }
        }
    }
}

struct DetailView_Previews: PreviewProvider {
    static var previews: some View {
        ThreadDetailView()
            .environmentObject(ThreadDetailViewModel())
    }
}
