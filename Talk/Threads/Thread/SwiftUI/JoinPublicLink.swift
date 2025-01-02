//
//  JoinPublicLink.swift
//  Talk
//
//  Created by hamed on 12/4/23.
//

import SwiftUI
import TalkViewModels
import TalkModels
import TalkUI
import Chat

struct JoinPublicLink: View {
    let viewModel: MessageRowViewModel
    private var message: HistoryMessageType { viewModel.message }

    var body: some View {
        Button {
            AppState.shared.objectsContainer.appOverlayVM.dialogView = AnyView(JoinToPublicConversationDialog(message: message))
        } label: {
            Text(verbatim: message.message ?? "")
                .foregroundStyle(Color.App.textSecondary)
                .disabled(true)
            //                HStack {
            //                    Text("Thread.join")
            //                        .foregroundStyle(Color.App.textPrimary)
            //                        .font(.iransansBoldBody)
            //                        .multilineTextAlignment(.center)
            //                }
            //                .buttonStyle(.plain)
            //                .frame(height: 52)
            //                .fixedSize(horizontal: false, vertical: true)
            //                .frame(minWidth: 196)
            //                .background(Color.App.bgSecondary)
            //                .clipShape(RoundedRectangle(cornerRadius: 8))
            //                .overlay(
            //                    RoundedRectangle(cornerRadius: 8)
            //                        .inset(by: 0.5)
            //                        .stroke(Color.App.gray8, lineWidth: 1)
            //                )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 10)
    }
}


struct JoinToPublicConversationDialog: View {
    let message: HistoryMessageType
    var appOverlayVM: AppOverlayViewModel {AppState.shared.objectsContainer.appOverlayVM}

    var body: some View {
        VStack(alignment: .trailing, spacing: 16) {
            Text("Thread.Join.question")
                .foregroundStyle(Color.App.textPrimary)
                .font(.iransansBoldSubheadline)
                .multilineTextAlignment(.leading)
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 16) {
                Button {
                    let publicLink = message.message?.links().first(where: {$0.contains(AppRoutes.joinLink)})
                    if let publicName = publicLink?.replacingOccurrences(of: AppRoutes.joinLink, with: "").replacingOccurrences(of: "\u{200f}", with: "")  {
                        AppState.shared.objectsContainer.threadsVM.joinPublicGroup(publicName)
                    }
                    appOverlayVM.dialogView = nil
                } label: {
                    Text("Thread.join")
                        .foregroundStyle(Color.App.accent)
                        .font(.iransansBody)
                        .frame(minWidth: 48, minHeight: 48)
                        .fontWeight(.medium)
                }

                Button {
                    appOverlayVM.dialogView = nil
                } label: {
                    Text("General.cancel")
                        .foregroundStyle(Color.App.textPlaceholder)
                        .font(.iransansBody)
                        .frame(minWidth: 48, minHeight: 48)
                        .fontWeight(.medium)
                }
            }
        }
        .frame(maxWidth: 320)
        .padding(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
        .background(MixMaterialBackground())
    }
}

struct JoinPublicLink_Previews: PreviewProvider {
    static var previews: some View {
        JoinPublicLink(viewModel: .init(message: Message(message: "\(AppRoutes.joinLink)FAKEUNIQUENAME") , viewModel: .init(thread: .init(id: 1))))
    }
}
