//
//  SwiftUIReactionCountRowWrapper.swift
//  Talk
//
//  Created by hamed on 7/22/24.
//

import Foundation
import SwiftUI
import TalkUI
import TalkViewModels
import TalkModels

struct SwiftUIReactionCountRowWrapper: UIViewRepresentable {
    let row: ReactionRowsCalculated.Row
    let isMe: Bool

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.frame = .zero
        return view
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {}
}
