//
//  CircleProgressConfig.swift
//  TalkUI
//
//  Created by Hamed Hosseini on 11/27/21.
//

import Foundation
import SwiftUI

@MainActor
public struct CircleProgressConfig {

    public static let normal: CircleProgressConfig = .init(progressFont: .fSubheadline,
                                                           fontWeight: .heavy,
                                                           forgroundColor: .indigo,
                                                           circleLineWidth: 4,
                                                           dimPathColor: Color.App.white.opacity(0.5))

    public static let small: CircleProgressConfig = .init(progressFont: .fCaption3,
                                                          fontWeight: .heavy,
                                                          forgroundColor: .indigo,
                                                          circleLineWidth: 1.0,
                                                          dimPathColor: Color.App.white.opacity(0.5))
    public var progressFont: Font
    public var fontWeight: Font.Weight
    public var forgroundColor: Color
    public var circleLineWidth: CGFloat
    public var dimPathColor: Color

    public init(progressFont: Font,
                fontWeight: Font.Weight,
                forgroundColor: Color,
                circleLineWidth: CGFloat,
                dimPathColor: Color
    ) {
        self.progressFont = progressFont
        self.fontWeight = fontWeight
        self.forgroundColor = forgroundColor
        self.circleLineWidth = circleLineWidth
        self.dimPathColor = dimPathColor
    }
}
