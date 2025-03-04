//
//  LoginView.swift
//  Talk
//
//  Created by Hamed Hosseini on 9/17/21.
//

import SwiftUI
import TalkModels
import TalkViewModels

import TalkUI

struct LoginNavigationContainerView: View {
    @EnvironmentObject var viewModel: LoginViewModel
    var addNewuser = false
    var onNewUserAdded: (() -> Void)?

    var body: some View {
        NavigationStack(path: $viewModel.path) {
            LoginContentView()
                .navigationDestination(for: LoginState.self) { _ in
                    VerifyContentView()
                }
        }
        .onReceive(viewModel.$state) { newState in
            if newState == .verify {
                viewModel.path.append(newState)
            } else if newState == .successLoggedIn {
                onNewUserAdded?()
            }
        }
        .animation(.easeOut, value: viewModel.state)
//        .onAppear {
//            viewModel.startNewPKCESession()
//        }
    }
}

struct LoginNavigationContainerView_Previews: PreviewProvider {
    static let loginVewModel = LoginViewModel(delegate: ChatDelegateImplementation.sharedInstance)
    static var previews: some View {
        LoginNavigationContainerView()
            .environmentObject(loginVewModel)
            .previewDisplayName("LoginNavigationContainerView")
    }
}
