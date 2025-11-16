//
//  VerifyContentView.swift
//  Talk
//
//  Created by hamed on 10/24/23.
//

import SwiftUI
import TalkViewModels
import TalkUI
import AdditiveUI
import TalkModels

struct VerifyContentView: View {
    @EnvironmentObject var viewModel: LoginViewModel
    @Environment(\.layoutDirection) var direction

    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            btnBack
            Spacer()
            descriptionContainer
            OTPNumbers()
                .frame(maxWidth: 420)
                .padding(.horizontal)
                .environment(\.layoutDirection, .leftToRight)
                .transition(.asymmetric(insertion: .scale(scale: 1), removal: .scale(scale: 0)))
            confirmCodeText
            OTPTimerView()
                .frame(maxWidth: 420)
            Spacer()
            submitButton
            errorView
        }
        .background(Color.App.bgPrimary)
        .animation(.easeInOut, value: viewModel.state)
        .animation(.easeInOut, value: viewModel.timerHasFinished)
        .transition(.move(edge: .trailing))
        .navigationBarBackButtonHidden(true)
        .onChange(of: viewModel.state) { newState in
            if newState == .failed || newState == .verificationCodeIncorrect {
                hideKeyboard()
            }
        }
        .onTapGesture {
            hideKeyboard()
        }
    }

    private var btnBack: some View {
        HStack {
            Button {
                viewModel.cancelTimer()
                viewModel.path.removeLast()
            } label: {
                Image(systemName: direction == .rightToLeft ? "arrow.right" : "arrow.left")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                    .foregroundStyle(Color.App.textPrimary)
                    .padding()
                    .fontWeight(.heavy)
            }
            Spacer()
        }
    }

    private var descriptionContainer: some View {
        VStack(spacing: 0) {
            Text("Login.Verify.verifyPhoneNumber")
                .font(Font.bold(.largeTitle))
                .foregroundColor(Color.App.textPrimary)
                .padding(.bottom, 2)

            HStack(spacing: 2) {
                let localized = "Login.Verfiy.verificationCodeSentTo".bundleLocalized()
                let formatted = String(format: localized, viewModel.text)
                Text(formatted)
                    .foregroundStyle(Color.App.textSecondary)
                    .font(Font.normal(.body))
                    .padding(EdgeInsets(top: 4, leading: 64, bottom: 4, trailing: 64))
                    .multilineTextAlignment(.center)
            }
            .font(Font.normal(.subheadline))
            .foregroundColor(Color.App.textPrimary)
        }
        .padding(.bottom, 40)
    }

    private var confirmCodeText: some View {
        HStack {
            Text("Login.verifyCode")
                .foregroundColor(Color.App.textPrimary)
                .font(Font.bold(.caption))
                .padding(.top, 8)
                .padding(.leading, 2)
            Spacer()
        }
        .frame(maxWidth: 420)
        .padding(EdgeInsets(top: 0, leading: 16, bottom: 8, trailing: 16))
    }

    private var submitButton: some View {
        SubmitBottomButton(text: "Login.Verify.title",
                           enableButton: Binding(get: {!viewModel.isLoading}, set: {_ in}),
                           isLoading: $viewModel.isLoading,
                           maxInnerWidth: 420
        ) {
            Task {
                await viewModel.verifyCode()
            }
        }
        .disabled(viewModel.isLoading)
    }

    @ViewBuilder
    private var errorView: some View {
        ErrorView(error: error)
            .frame(height: canShowError ? nil : 0)
            .clipped()
    }

    private var canShowError: Bool {
        viewModel.state == .failed || viewModel.state == .verificationCodeIncorrect
    }

    private var error: String {
        return viewModel.state == .verificationCodeIncorrect ? "Errors.failedTryAgain" : "Errors.Login.Verify.incorrectCode"
    }
}

struct VerifyContentView_Previews: PreviewProvider {
    static let loginVewModel = LoginViewModel(delegate: ChatDelegateImplementation.sharedInstance)
    static var previews: some View {
        NavigationStack {
            VerifyContentView()
                .environmentObject(loginVewModel)
                .onAppear {
                    loginVewModel.text = "09369161601"
                    loginVewModel.animateObjectWillChange()
                }
        }
        .previewDisplayName("VerifyContentView")
    }
}
