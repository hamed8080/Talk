//
//  DetailPublicLinkSection.swift
//  Talk
//
//  Created by hamed on 5/6/24.
//

import SwiftUI
import TalkViewModels
import TalkModels

struct DetailPublicLinkSection: View {
    @EnvironmentObject var viewModel: ThreadDetailViewModel
    private var shortJoinLink: String { "talk/\(viewModel.thread?.uniqueName ?? "")" }
    private var joinLink: String { "\(AppRoutes.joinLink)\(viewModel.thread?.uniqueName ?? "")" }

    var body: some View {
        if viewModel.thread?.uniqueName != nil {
            Button {
                UIPasteboard.general.string = joinLink
                let icon = Image(systemName: "doc.on.doc")
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.App.textPrimary)
                AppState.shared.objectsContainer.appOverlayVM.toast(leadingView: icon, message: "General.copied", messageColor: Color.App.textPrimary)
            } label: {
                SectionRowContainer(key: "Thread.inviteLink", value: shortJoinLink, lineLimit: 1, button: AnyView(EmptyView()))
            }
        }
    }

    //    var qrButton: some View {
    //        Button {
    //            withAnimation {
    //                UIPasteboard.general.string = joinLink
    //            }
    //        } label: {
    //            Image(systemName: "qrcode")
    //                .resizable()
    //                .scaledToFit()
    //                .frame(width: 20, height: 20)
    //                .padding()
    //                .foregroundColor(Color.App.white)
    //                .contentShape(Rectangle())
    //        }
    //        .frame(width: 40, height: 40)
    //        .background(Color.App.textSecondary)
    //        .clipShape(RoundedRectangle(cornerRadius:(20)))
    //    }
}

struct DetailPublicLinkSection_Previews: PreviewProvider {
    static var previews: some View {
        DetailPublicLinkSection()
    }
}
