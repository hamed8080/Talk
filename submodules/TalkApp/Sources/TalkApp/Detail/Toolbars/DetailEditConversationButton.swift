//
//  DetailEditConversationButton.swift
//  Talk
//
//  Created by hamed on 5/6/24.
//

import SwiftUI
import TalkViewModels

struct DetailEditConversationButton: View {
    @EnvironmentObject var viewModel: ThreadDetailViewModel
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        if viewModel.canShowEditConversationButton == true, viewModel.thread?.closed == false {
            NavigationLink {
                if viewModel.canShowEditConversationButton, let viewModel = viewModel.editConversationViewModel {
                    EditGroup(threadVM: viewModel.threadVM)
                        .injectAllObjects()
                        .environmentObject(viewModel)
                        .navigationBarBackButtonHidden(true)
                        .onAppear {
                            AppState.shared.objectsContainer.navVM.pushToLinkId(id: "DetailEditConversation-\(viewModel.thread.id ?? 0)" )
                        }
                        .onDisappear {
                            AppState.shared.objectsContainer.navVM.popLinkId()
                        }
                }
            } label: {
                Image("ic_edit")
                    .resizable()
                    .scaledToFit()
                    .padding(14)
                    .frame(width: ToolbarButtonItem.buttonWidth, height: ToolbarButtonItem.buttonWidth)
                    .foregroundStyle(colorScheme == .dark ? Color.App.accent : Color.App.white)
                    .fontWeight(.heavy)
            }
        }
    }
}

struct EditConversationButton_Previews: PreviewProvider {
    static var previews: some View {
        DetailEditConversationButton()
    }
}
