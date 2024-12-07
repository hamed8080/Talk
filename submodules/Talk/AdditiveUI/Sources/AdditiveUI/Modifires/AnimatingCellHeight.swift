//
// AnimatingCellHeight.swift
// Copyright (c) 2022 AdditiveUI
//
// Created by Hamed Hosseini on 12/14/22


#if canImport(SwiftUI)
import SwiftUI

public struct AnimatingCellHeight: Animatable {
    public var height: CGFloat = 0

    public init(height: CGFloat) {
        self.height = height
    }

    public var animatableData: CGFloat {
        get { height }
        set { height = newValue }
    }
}
#endif
