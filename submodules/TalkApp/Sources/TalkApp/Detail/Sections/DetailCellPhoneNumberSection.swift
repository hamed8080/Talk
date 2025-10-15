//
//  DetailCellPhoneNumberSection.swift
//  Talk
//
//  Created by hamed on 5/6/24.
//

import SwiftUI
import TalkViewModels

struct DetailCellPhoneNumberSection: View {
    @EnvironmentObject var viewModel: ParticipantDetailViewModel

    var body: some View {
        if let cellPhoneNumber = viewModel.cellPhoneNumber.validateString {
            SectionRowContainer(key: "Participant.Search.Type.cellphoneNumber", value: cellPhoneNumber)
                .onTapGesture {
                    UIPasteboard.general.string = cellPhoneNumber
                    let imageView = UIImageView(image: UIImage(systemName: "phone"))
                    AppState.shared.objectsContainer.appOverlayVM.toast(
                        leadingView: imageView,
                        message: "General.copied",
                        messageColor: Color.App.textPrimaryUIColor!
                    )
                }
        }
    }
}

struct DetailCellPhoneNumberSection_Previews: PreviewProvider {
    static var previews: some View {
        DetailCellPhoneNumberSection()
    }
}
