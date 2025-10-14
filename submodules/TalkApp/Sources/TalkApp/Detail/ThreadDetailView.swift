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
                    if viewWidth != 0 {
                        DetailTabContainer(maxWidth: viewWidth)
                            .id("DetailTabContainer")
                    }
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
        .onAppear {
            AppState.shared.objectsContainer.navVM.pushToLinkId(id: "ThreadDetailView-\(viewModel.threadVM?.id ?? 0)")
        }
        .onDisappear {
            Task(priority: .background) {
                viewModel.threadVM?.searchedMessagesViewModel.reset()
            }
            
            /// We make sure user is not moving to edit thread detail or contact
            let linkId = AppState.shared.objectsContainer.navVM.getLinkId() as? String ?? ""
            if linkId == "ThreadDetailView-\(viewModel.threadVM?.id ?? 0)" {
                viewModel.dismissBySwipe()
            }
        }
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

struct DetailViewWrapper: View {
    private let container = AppState.shared.objectsContainer!
    let detailViewModel: ThreadDetailViewModel
    
    var body: some View {
        ThreadDetailView()
            .injectAllObjects()
            .environmentObject(detailViewModel)        
    }
}

struct DetailView_Previews: PreviewProvider {
    static var previews: some View {
        ThreadDetailView()
            .environmentObject(ThreadDetailViewModel())
    }
}
