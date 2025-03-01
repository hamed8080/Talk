//
//  OTPTimerView.swift
//  Talk
//
//  Created by hamed on 5/8/24.
//

import SwiftUI
import TalkViewModels
import TalkModels

struct OTPTimerView: View {
    @EnvironmentObject var viewModel: LoginViewModel

    var body: some View {
        HStack {
            if !viewModel.timerHasFinished {
                let localized = String(localized: .init("Login.Verify.timer"), bundle: Language.preferedBundle)
                let formatted = String(format: localized, viewModel.timerString)
                Text(formatted)
                    .foregroundStyle(Color.App.textSecondary)
                    .font(.fCaption)
                    .padding(EdgeInsets(top: 20, leading: AppState.isInSlimMode ? 12 : 6, bottom: 0, trailing: 0))
            } else {
                Button {
                    viewModel.resend()
                } label: {
                    HStack {
                        Image(systemName: "gobackward")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 16, height: 16)
                            .foregroundStyle(.blue)
                        Text("Login.Verify.resendCode")
                    }
                }
                .foregroundStyle(Color.App.textPrimary)
                .padding(.top, 20)
                .font(.fCaption)

            }
            Spacer()
        }
    }
}

struct OTPTimerView_Previews: PreviewProvider {
    static var previews: some View {
        OTPTimerView()
    }
}
