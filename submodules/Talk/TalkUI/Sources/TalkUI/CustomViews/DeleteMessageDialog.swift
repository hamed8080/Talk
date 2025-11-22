//
//  DeleteMessageDialog.swift
//  
//
//  Created by hamed on 7/23/23.
//

import SwiftUI
import TalkViewModels

public struct DeleteMessageDialog: View {
    @EnvironmentObject var appOverlayVM: AppOverlayViewModel
    private let viewModel: DeleteMessagesViewModelModel

    public init(viewModel: DeleteMessagesViewModelModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(alignment: .trailing, spacing: 16) {
            Text("DeleteMessageDialog.title")
                .foregroundStyle(Color.App.textPrimary)
                .font(Font.bold(.subheadline))
                .multilineTextAlignment(.leading)
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)

            Text("DeleteMessageDialog.subtitle")
                .foregroundStyle(Color.App.textPrimary)
                .font(Font.normal(.body))
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)

            if viewModel.hasPinnedMessage {
                Text(viewModel.isSingle ? "DeleteMessageDialog.singleDeleteIsPinMessage" : "DeleteMessageDialog.multipleDeleteContainsPinMessage")
                    .foregroundStyle(Color.App.textSecondary)
                    .font(Font.normal(.caption2))
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
            }

            HStack {
                if !viewModel.isVstackLayout {
                    HStack(spacing: 16) {
                        buttons
                    }
                } else {
                    VStack(alignment: .leading, spacing: 12) {
                        buttons
                    }
                    .padding(.bottom, 4)
                }
                Spacer()
            }
        }
        .frame(maxWidth: 320)
        .padding(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
        .background(MixMaterialBackground())
        .onDisappear {
            Task {
                await viewModel.cleanup()
            }
        }
    }

    @ViewBuilder var buttons: some View {
        if viewModel.deleteForMe {
            Button {
                viewModel.deleteMessagesForMe()
            } label: {
                Text(viewModel.isSelfThread ? "General.delete" : "Messages.deleteForMe")
                    .foregroundStyle(viewModel.isSelfThread ? Color.App.red : Color.App.accent)
                    .font(Font.bold(.caption))
            }
        }

        if viewModel.deleteForOthers {
            Button {
                viewModel.deleteForAll()
            } label: {
                Text("Messages.deleteForAll")
                    .foregroundStyle(Color.App.red)
                    .font(Font.bold(.caption))
            }
        } else if viewModel.deleteForOthserIfPossible {
            Button {
                Task {
                    await viewModel.deleteForMeAndAllOthersPossible()
                }
            } label: {
                Text("DeleteMessageDialog.deleteForMeAllOtherIfPossible")
                    .foregroundStyle(Color.App.red)
                    .multilineTextAlignment(.leading)
                    .font(Font.bold(.caption))
            }
        }
    }
}

struct DeleteMessageDialog_Previews: PreviewProvider {
    static var previews: some View {
        DeleteMessageDialog(viewModel: .init())
    }
}
