//
//  MoveToFileContextMenuItemViewModifier.swift
//  TalkApp
//
//  Created by Hamed Hosseini on 7/10/25.
//

import SwiftUI
import TalkModels
import ActionableContextMenu
import TalkViewModels
import TalkUI

struct MoveToFileContextMenuItemViewModifier<V: View>: ViewModifier {
    var newInstance: V
    let viewModel: ThreadDetailViewModel
    let rowModel: TabRowModel
    
    func body(content: Content) -> some View {
        content
            .newCustomContextMenu {
                newInstance
                    .environment(\.layoutDirection, Language.isRTL ? .rightToLeft : .leftToRight)
                    .environmentObject(rowModel)
                    .disabled(true)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } menus: {
                VStack {
                    ContextMenuButton(title: "General.showMessage".bundleLocalized(), image: "message.fill", bundle: Language.preferedBundle, isRTL: Language.isRTL) {
                        rowModel.moveToMessage(viewModel)
                    }
                }
                .foregroundColor(.primary)
                .frame(width: 196)
                .background(MixMaterialBackground())
                .clipShape(RoundedRectangle(cornerRadius:((12))))
                .environmentObject(rowModel)
                .environmentObject(viewModel)
            }
    }
}

extension View {
    func appyDetailViewContextMenu<V: View>(_ newInstance: V, _ rowModel: TabRowModel, _ viewModel: ThreadDetailViewModel) -> some View {
        self.modifier(MoveToFileContextMenuItemViewModifier(newInstance: newInstance, viewModel: viewModel, rowModel: rowModel))
            .font(Font.normal(.body))
    }
}
