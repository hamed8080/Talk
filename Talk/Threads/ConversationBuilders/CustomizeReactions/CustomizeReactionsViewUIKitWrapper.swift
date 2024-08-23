//
//  2.swift
//  Talk
//
//  Created by hamed on 7/30/24.
//

import Foundation
import UIKit
import TalkViewModels
import ChatModels
import SwiftUI

struct CustomizeReactionsViewUIKitWrapper: UIViewControllerRepresentable {
    let viewModel: ThreadViewModel?

    func makeUIViewController(context: Context) -> some UIViewController {
        let vc = CustomizeReactionsViewController()
        vc.viewModel = viewModel
        return vc
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {

    }
}

struct CustomizeReactions_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = ThreadViewModel(thread: .init(id: 1, reactionStatus: .enable))
        CustomizeReactionsViewUIKitWrapper(viewModel: viewModel)
            .ignoresSafeArea(.all)
            .navigationBarHidden(true)
    }
}
