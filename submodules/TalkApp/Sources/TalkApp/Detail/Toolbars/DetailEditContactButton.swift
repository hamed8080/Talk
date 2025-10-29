//
//  DetailEditContactButton.swift
//  Talk
//
//  Created by hamed on 5/6/24.
//

import SwiftUI
import TalkViewModels

struct DetailEditContactButton: View {
    @EnvironmentObject var viewModel: ParticipantDetailViewModel
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        if viewModel.partnerContact != nil {
            NavigationLink {
                EditContactInParticipantDetailView()
                    .injectAllObjects()
                    .environmentObject(viewModel)
                    .background(Color.App.bgSecondary)
                    .navigationBarBackButtonHidden(true)
                    .onAppear {
                        AppState.shared.objectsContainer.navVM.pushToLinkId(id: "EditContact-\(viewModel.partnerContact?.id ?? 0)")
                    }
                    .onDisappear {
                        AppState.shared.objectsContainer.navVM.popLinkId(id: "EditContact-\(viewModel.partnerContact?.id ?? 0)")
                    }
            } label: {
                Image("ic_edit")
                    .resizable()
                    .scaledToFit()
                    .padding(14)
                    .frame(width: ToolbarButtonItem.buttonWidth, height: ToolbarButtonItem.buttonWidth)
                    .foregroundStyle(colorScheme == .dark ?  Color.App.accent : Color.App.white)
                    .fontWeight(.heavy)
            }
        }
    }
}

struct DetailEditContactButton_Previews: PreviewProvider {
    static var previews: some View {
        DetailEditContactButton()
    }
}
