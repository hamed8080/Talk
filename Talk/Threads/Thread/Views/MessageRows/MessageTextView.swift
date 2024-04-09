//
//  MessageTextView.swift
//  Talk
//
//  Created by hamed on 11/14/23.
//

import SwiftUI
import TalkUI
import ChatModels
import TalkViewModels

struct MessageTextView: View {
    @EnvironmentObject var viewModel: MessageRowViewModel
    private var message: Message { viewModel.message }

    var body: some View {
        // TODO: TEXT must be alignment and image must be fit
        if !viewModel.rowType.isPublicLink, message.message?.isEmpty == false {
            Text(viewModel.markdownTitle)
                .multilineTextAlignment(viewModel.isEnglish ? .leading : .trailing)
                .lineSpacing(8)
                .padding(viewModel.paddings.textViewPadding)
                .font(.iransansBody)
                .foregroundColor(Color.App.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, viewModel.paddings.textViewSpacingTop) /// We don't use spacing in the Main row in VStack because we don't want to have extra spcace.
                .background(viewModel.isMe ? Color.App.bgChatMe : Color.App.bgChatUser)
        } else if let fileName = message.uploadFileName, message.isUnsentMessage == true {
            Text(fileName)
                .multilineTextAlignment(viewModel.isEnglish ? .leading : .trailing)
                .padding(.horizontal, 6)
                .font(.iransansBody)
                .foregroundColor(Color.App.textPrimary)
                .padding(.top, viewModel.paddings.textViewSpacingTop) /// We don't use spacing in the Main row in VStack because we don't want to have extra spcace.
        }
    }
}

struct MessageTextView_Previews: PreviewProvider {
    static var previews: some View {
        MessageTextView()
    }
}
