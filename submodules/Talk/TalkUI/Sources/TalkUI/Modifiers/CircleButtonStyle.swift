//
//  CircleButtonStyle.swift
//  TalkUI
//
//  Created by Hamed Hosseini on 11/30/21.
//

import Foundation
import SwiftUI

public struct CircleButtonStyle: ButtonStyle {
    var backgroundColor: Color = .primary
    var shadow: CGFloat = 6
    var cornerRadius: CGFloat = 0

    public init(backgroundColor: Color = .primary, shadow: CGFloat = 6, cornerRadius: CGFloat = 0) {
        self.backgroundColor = backgroundColor
        self.shadow = shadow
        self.cornerRadius = cornerRadius
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius:(cornerRadius)))
            .buttonStyle(.borderedProminent)
            .shadow(radius: configuration.isPressed ? 0 : shadow)
            .scaleEffect(x: configuration.isPressed ? 0.98 : 1, y: configuration.isPressed ? 0.98 : 1)
            .animation(.easeInOut, value: configuration.isPressed)
    }
}

public extension ButtonStyle where Self == CircleButtonStyle {

    static func circle(backgroundColor: Color = .primary,
                                  shadow: CGFloat = 6,
                                  cornerRadius: CGFloat = 0) -> CircleButtonStyle {
        CircleButtonStyle(
            backgroundColor: backgroundColor,
            shadow: shadow,
            cornerRadius: cornerRadius
        )
    }
    static var circle: CircleButtonStyle { CircleButtonStyle() }
}
