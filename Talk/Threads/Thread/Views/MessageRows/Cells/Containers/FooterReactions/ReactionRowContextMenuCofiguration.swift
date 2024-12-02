//
//  ReactionRowContextMenuCofiguration.swift
//  Talk
//
//  Created by hamed on 7/22/24.
//

import Foundation
import SwiftUI
import UIKit
import TalkViewModels
import TalkModels

public class ReactionRowContextMenuCofiguration {
    public static func config(interaction: UIContextMenuInteraction) -> UIContextMenuConfiguration? {
        UIContextMenuConfiguration(actionProvider:  { _ in
            return UIMenu(title: "", children: [closeAction(interaction)])
        })
    }

    public static func targetedView(view: UIView, row: ReactionRowsCalculated.Row, viewModel: MessageRowViewModel?) -> UITargetedPreview? {
        guard let viewModel = viewModel else { return nil }
        let targetedView = UIPreviewTarget(container: view, center: view.center)
        let isDark = view.traitCollection.userInterfaceStyle == .dark
        let rowCountWithTabView = RowCountWithTabViewContxtMenu(viewModel, row, isDark)
        let vc = hostVC(rootView: rowCountWithTabView)
        return UITargetedPreview(view: vc.view, parameters: params, target: targetedView)
    }
}

fileprivate extension ReactionRowContextMenuCofiguration {
    private static func closeAction(_ interaction: UIContextMenuInteraction) -> UIAction {
        UIAction(title: "General.close".bundleLocalized(), image: UIImage(systemName: "xmark.circle")) { _ in
            interaction.dismissMenu()
        }
    }

    private static var params: UIPreviewParameters {
        let params = UIPreviewParameters()
        params.backgroundColor = .clear
        params.shadowPath = UIBezierPath()
        return params
    }

    private static func hostVC(rootView: some View) -> UIHostingController<some View> {
        let vc = UIHostingController(rootView: rootView)
        vc.view.frame = .init(origin: .zero, size: .init(width: 300, height: 400))
        vc.view.backgroundColor = .clear
        vc.preferredContentSize = vc.view.frame.size
        return vc
    }
}

fileprivate struct RowCountWithTabViewContxtMenu: View {
    let vm: MessageRowViewModel
    let tabVM: ReactionTabParticipantsViewModel
    let row: ReactionRowsCalculated.Row
    let isDark: Bool
    
    init(_ vm: MessageRowViewModel, _ row: ReactionRowsCalculated.Row, _ isDark: Bool) {
        self.vm = vm
        let tabVM = ReactionTabParticipantsViewModel(messageId: vm.message.id ?? -1)
        tabVM.viewModel = vm.threadVM?.reactionViewModel
        self.tabVM = tabVM
        self.row = row
        self.isDark = isDark
    }

    var body: some View {
        VStack(alignment: vm.calMessage.isMe ? .leading : .trailing) {
            SwiftUIReactionCountRowWrapper(row: row, isMe: vm.calMessage.isMe)
                .frame(minWidth: 0)
                .frame(height: 32)
                .fixedSize()
                .environment(\.colorScheme, isDark ? .dark : .light)
                .disabled(true)

            MessageReactionDetailView(message: vm.message, row: row)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .environmentObject(tabVM)
    }
}
