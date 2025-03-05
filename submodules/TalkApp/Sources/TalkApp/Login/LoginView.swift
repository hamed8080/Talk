//
//  LoginView.swift
//  Talk
//
//  Created by hamed on 10/24/23.
//

import SwiftUI
import TalkUI
import TalkViewModels
import TalkModels

struct LoginContentView: View {
    @EnvironmentObject var viewModel: LoginViewModel
    @FocusState var isFocused

    var body: some View {
        VStack(alignment: .center, spacing: 16) {
            Spacer()
            Group {
                Text("Login.loginOrSignup")
                    .font(.fBoldLargeTitle)
                    .foregroundColor(Color.App.textPrimary)
                Text("Login.subtitle")
                    .font(.fSubheadline)
                    .foregroundColor(Color.App.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 48)
                    .padding(.bottom, 40)
                    .frame(maxWidth: 420)

                let key = viewModel.selectedServerType == .integration ? "Login.staticToken" : "Login.phoneNumber"
                let placeholder = key.bundleLocalized()
                TextField(placeholder, text: $viewModel.text)
                    .focused($isFocused)
                    .keyboardType(.phonePad)
                    .font(.fBody)
                    .padding()
                    .frame(maxWidth: 420)
                    .applyAppTextfieldStyle(topPlaceholder: viewModel.selectedServerType == .integration ? "Login.staticToken" : "Settings.phoneNumber", isFocused: isFocused) {
                        isFocused.toggle()
                    }

                if viewModel.isValidPhoneNumber == false {
                    ErrorView(error: "Errors.Login.invalidPhoneNumber")
                        .padding(.horizontal)
                }

                if viewModel.state == .failed {
                    ErrorView(error: "Errors.failedTryAgain")
                        .padding(.horizontal)
                }

//                Text("Login.footer")
//                    .multilineTextAlignment(.center)
//                    .font(.fFootnote)
//                    .fixedSize(horizontal: false, vertical: true)
//                    .foregroundColor(.gray.opacity(1))
                if EnvironmentValues.isTalkTest {
                    Picker("Server", selection: $viewModel.selectedServerType) {
                        ForEach(ServerTypes.allCases) { server in
                            Text(server.rawValue)
                                .textCase(.uppercase)
                                .lineLimit(1)
                        }
                    }
                    .pickerStyle(.menu)
                    .sandboxLabel()
                }
            }

            Spacer()

            SubmitBottomButton(text: "Login.title",
                               enableButton: Binding(get: {!viewModel.isLoading}, set: {_ in}),
                               isLoading: $viewModel.isLoading,
                               maxInnerWidth: 420
            ) {
                if viewModel.isPhoneNumberValid() {
                    viewModel.login()
                }
            }
            .disabled(viewModel.isLoading)
        }
        .background(Color.App.bgPrimary.ignoresSafeArea())
        .animation(.easeInOut, value: isFocused)
        .animation(.easeInOut, value: viewModel.selectedServerType)
        .transition(.move(edge: .trailing))
        .onChange(of: viewModel.state) { newState in
            if newState != .failed {
                hideKeyboard()
            }
        }
        .onTapGesture {
            hideKeyboard()
        }
        .onAppear {
            isFocused = true
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static let loginVewModel = LoginViewModel(delegate: ChatDelegateImplementation.sharedInstance)
    static var previews: some View {
        NavigationStack {
            LoginContentView()
                .environmentObject(loginVewModel)
        }
        .previewDisplayName("LoginContentView")
    }
}
