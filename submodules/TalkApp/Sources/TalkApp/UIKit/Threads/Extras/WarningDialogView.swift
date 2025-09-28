//
//  WarningDialogView.swift
//  TalkUI
//
//  Created by Hamed Hosseini on 9/28/25.
//

import SwiftUI
import TalkUI

public struct WarningDialogView: View {
    @EnvironmentObject var appOverlayVM: AppOverlayViewModel
    let message: String

    public init(message: String) {
        self.message = message
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(message)
                .foregroundStyle(Color.App.textPrimary)
                .font(.fBoldSubheadline)
                .multilineTextAlignment(.leading)
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .trailing, spacing: 20) {
                Button {
                    appOverlayVM.dialogView = nil
                } label: {
                    Text("General.close")
                        .foregroundStyle(Color.App.accent)
                        .font(.fBoldBody)
                        .fontWeight(.medium)
                }
            }
        }
        .frame(maxWidth: 320)
        .padding(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
        .background(MixMaterialBackground())
    }
}
