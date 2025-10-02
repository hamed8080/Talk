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
    @State private var downloadingBundle: Bool = true

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

                let key = viewModel.selectedServerType == .integration ? "Login.staticToken" : "Login.phoneNumberHint"
                let placeholder = key.bundleLocalized()
                
                let topPlaceHolder = viewModel.selectedServerType == .integration ? "Login.staticToken" : "Settings.phoneNumber"
                TextField(placeholder, text: $viewModel.text)
                    .focused($isFocused)
                    .keyboardType(.phonePad)
                    .font(.fBody)
                    .padding()
                    .frame(maxWidth: 420)
                    .multilineTextAlignment(.leading)
                    .applyAppTextfieldStyleWithLeadingView(
                        topPlaceholder: topPlaceHolder.bundleLocalized(),
                        isFocused: isFocused,
                        forcedLayoutDirection: .leftToRight,
                        leadingView: leadingViewPhoneNumber) { isFocused.toggle() }
                    .onChange(of: viewModel.text) { newValue in
                        if newValue.first == "0", viewModel.state == .login {
                            viewModel.text = ""
                        }
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
        .disabled(downloadingBundle)
        .allowsHitTesting(!downloadingBundle)
        .opacity(downloadingBundle ? 0.4 : 1.0)
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
        }.task {
            /// Prevent app crashes while the bundle is nil and accessing url inside the bundle
            let bundleManager = BundleManager()
            while(!bundleManager.isBundleDownloaded()) {
                try? await Task.sleep(for: .seconds(0.2))
            }
            downloadingBundle = false
        }.overlay(alignment: .center) {
            if downloadingBundle {
                ProgressView()
                    .progressViewStyle(.circular)
            }
        }
    }
    
    @ViewBuilder
    private var leadingViewPhoneNumber: some View {
        if viewModel.selectedServerType != .integration {
            HStack {
                Text(verbatim: "+98")
                    .font(.fBody)
                    .foregroundStyle(Color.App.accent)
                
                Rectangle()
                    .fill(.gray)
                    .frame(width: 1)
            }
            .frame(height: 24)
            .padding(.leading, 12)
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
