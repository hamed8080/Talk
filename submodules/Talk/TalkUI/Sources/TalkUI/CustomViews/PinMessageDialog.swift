//
//  PinMessageDialog.swift
//
//
//  Created by hamed on 7/23/23.
//

import SwiftUI
import TalkViewModels
import TalkModels
import Chat

public struct PinMessageDialog: View {
    @EnvironmentObject var appOverlayVM: AppOverlayViewModel
    var threadVM: ThreadViewModel
    let message: Message

    public init(message: Message, threadVM: ThreadViewModel) {
        self.threadVM = threadVM
        self.message = message
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("PinMessageDialog.title")
                .foregroundStyle(Color.App.textPrimary)
                .font(Font.bold(.subheadline))
                .multilineTextAlignment(.leading)
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading, spacing: 20) {
                Button {
                    threadVM.threadPinMessageViewModel.togglePinMessage(message, notifyAll: true)
                    appOverlayVM.dialogView = nil
                } label: {
                    Text("PinMessageDialog.pinAndNotify")
                        .foregroundStyle(Color.App.accent)
                        .font(Font.bold(.body))
                }

                Button {
                    threadVM.threadPinMessageViewModel.togglePinMessage(message, notifyAll: false)
                    appOverlayVM.dialogView = nil
                } label: {
                    Text("PinMessageDialog.justPin")
                        .foregroundStyle(Color.App.accent)
                        .font(Font.bold(.body))
                }

                Button {
                    appOverlayVM.dialogView = nil
                } label: {
                    Text("General.cancel")
                        .foregroundStyle(Color.App.textPlaceholder)
                        .font(Font.bold(.body))
                        .fontWeight(.medium)
                }
            }
        }
        .frame(maxWidth: 320)
        .padding(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
        .background(MixMaterialBackground())
    }
}

struct PinMessageDialog_Previews: PreviewProvider {
    static var previews: some View {
        PinMessageDialog(message: .init(id: 1), threadVM: .init(thread: .init(id: 1)))
    }
}
