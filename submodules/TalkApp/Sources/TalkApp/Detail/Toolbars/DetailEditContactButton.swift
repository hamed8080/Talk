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
                    .environmentObject(viewModel)
                    .background(Color.App.bgSecondary)
                    .navigationBarBackButtonHidden(true)
            } label: {
                Image("ic_edit")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                    .padding(8)
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
