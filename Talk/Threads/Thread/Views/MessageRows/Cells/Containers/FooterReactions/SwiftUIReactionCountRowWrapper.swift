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

    func makeUIView(context: Context) -> some UIView {
        let view = ReactionCountRowView(frame: .zero, isMe: isMe)
        view.prepareContextMenu()
        view.setValue(row: row)
        if row.isMyReaction == false {
            view.backgroundColor = Color.App.accentUIColor?.withAlphaComponent(0.8)
        }
        return view
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {}
}
