//
//  File.swift
//  
//
//  Created by hamed on 10/27/23.
//

import Foundation
import SwiftUI

public struct ContextMenuButton: View {
    private let title: String
    private let image: String
    private let showSeparator: Bool
    private let iconColor: Color?
    private let bundle: Bundle
    private let isRTL: Bool
    private let action: (() -> Void)?
    @State private var scale: CGFloat = 0.0001
    @EnvironmentObject var viewModel: ContextMenuModel
    @Environment(\.colorScheme) var scheme

    public init(title: String, image: String, iconColor: Color? = nil, showSeparator: Bool = true, bundle: Bundle, isRTL: Bool, action: ( () -> Void)?) {
        self.title = title
        self.image = image
        self.showSeparator = showSeparator
        self.action = action
        self.bundle = bundle
        self.iconColor = iconColor
        self.isRTL = isRTL
    }

    public var body: some View {
        Button {
            action?()
            viewModel.isPresented = false
        } label: {
            HStack {
                if !image.isEmpty {
                    Image(systemName: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 18, height: 18)
                        .foregroundStyle(iconColor ?? (scheme == .dark ? Color(red: 0.6, green: 0.62, blue: 0.68) : Color(red: 0.36, green: 0.4, blue: 0.47)))
                }
                Text(String(localized: .init(title), bundle: bundle))
                    .padding(.leading, 12)
                Spacer()
            }
            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
            .scaleEffect(x: scale, y: scale, anchor: .center)
        }
        .environment(\.layoutDirection, isRTL ? .rightToLeft : .leftToRight)
        .padding(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
        .onAppear {
            withAnimation(.interpolatingSpring(mass: 1.0, stiffness: 0.3, damping: 0.5, initialVelocity: 0).speed(30)) {
                scale = 1.0
            }
        }
    }
}
