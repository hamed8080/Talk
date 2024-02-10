//
//  NavigationBackButton.swift
//  Talk
//
//  Created by hamed on 10/5/23.
//

import SwiftUI
import TalkViewModels

public struct NavigationBackButton: View {
    @EnvironmentObject var navViewModel: NavigationModel
    @Environment(\.dismiss) var dismiss
    let action: (() -> ())?

    public init(action: (() -> Void)? = nil) {        
        self.action = action
    }

    public var body: some View {
        Button {
            action?()
            dismiss()
        } label : {
            HStack(spacing: 4) {
                Image(systemName: "chevron.backward")
                    .resizable()
                    .scaledToFit()
                    .padding(EdgeInsets(top: 8, leading: 0, bottom: 12, trailing: navViewModel.previousTitle.isEmpty ? 8 : 2))
                    .fontWeight(.medium)
                let localized = String(localized: .init(navViewModel.previousTitle))
                let maxLength = UIDevice.current.userInterfaceIdiom == .pad ? 35 : 15
                let string = String(localized.prefix(maxLength))
                Text(string)
                    .font(.iransansBody)
                    .offset(y: -2)
            }
            .foregroundColor(Color.App.toolbarButton)
            .contentShape(Rectangle())
        }
        .frame(minWidth: ToolbarButtonItem.buttonWidth, minHeight: ToolbarButtonItem.buttonWidth)
    }
}

public struct NormalNavigationBackButton: View {
    @Environment(\.dismiss) var dismiss

    public init() {}

    public var body: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.backward")
                        .resizable()
                        .scaledToFit()
                        .fontWeight(.medium)
                        .frame(maxWidth: 16, maxHeight: 16)
                    Text("General.back")
                        .font(.iransansBody)
                }
            }
            Spacer()
        }
        .padding(16)
        .background(.ultraThinMaterial)        
    }
}

struct NavigationBackButton_Previews: PreviewProvider {
    static var previews: some View {
        NavigationBackButton {

        }
    }
}
