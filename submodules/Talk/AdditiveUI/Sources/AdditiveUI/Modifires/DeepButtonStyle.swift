//
// DeepButtonStyle.swift
// Copyright (c) 2022 AdditiveUI
//
// Created by Hamed Hosseini on 12/14/22

#if canImport(SwiftUI)
import SwiftUI
public struct DeepButtonStyle: ButtonStyle {
    var backgroundColor: Color = .primary
    var shadow: CGFloat = 6
    var cornerRadius: CGFloat = 0
    
    public init(backgroundColor: Color, shadow: CGFloat, cornerRadius: CGFloat) {
        self.backgroundColor = backgroundColor
        self.shadow = shadow
        self.cornerRadius = cornerRadius
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(backgroundColor)
            .cornerRadius(cornerRadius)
            .shadow(radius: configuration.isPressed ? 0 : shadow)
            .scaleEffect(x: configuration.isPressed ? 0.98 : 1, y: configuration.isPressed ? 0.98 : 1)
            .animation(.easeInOut, value: configuration.isPressed)
    }
}
#endif
