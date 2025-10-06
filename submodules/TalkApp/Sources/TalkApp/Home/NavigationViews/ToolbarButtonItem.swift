//
//  ToolbarButtonItem.swift
//  Talk
//
//  Created by hamed on 10/1/23.
//

import Foundation
import SwiftUI

public struct ToolbarButtonItem: View {
    let imageName: String
    let hint: String
    let padding: CGFloat
    let action: (() -> Void)?
    static let buttonWidth: CGFloat = 48

    init(imageName: String, hint: String = "", padding: CGFloat = 10, action: (() -> Void)? = nil) {
        self.padding = padding
        self.imageName = imageName
        self.hint = hint
        self.action = action
    }

    public var body: some View {
        Button {
            action?()
        } label: {
            Image(systemName: imageName)
                .resizable()
                .scaledToFit()
                .padding(padding)
                .frame(width: ToolbarButtonItem.buttonWidth, height: ToolbarButtonItem.buttonWidth)
                .accessibilityHint(hint)
                .fontWeight(.medium)
        }
        .frame(width: ToolbarButtonItem.buttonWidth, height: ToolbarButtonItem.buttonWidth)
    }
}
