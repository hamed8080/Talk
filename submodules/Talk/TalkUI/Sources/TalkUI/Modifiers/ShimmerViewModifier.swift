//
//  ShimmerViewModifier.swift
//  Talk
//
//  Created by hamed on 2/6/24.
//

import SwiftUI
import TalkViewModels

public struct ShimmerViewModifier: ViewModifier {
    @EnvironmentObject var viewModel: ShimmerItemViewModel
    let cornerRadius: CGFloat
    let startFromLeading: Bool

    public init(cornerRadius: CGFloat, startFromLeading: Bool = true) {
        self.cornerRadius = cornerRadius
        self.startFromLeading = startFromLeading
    }

    private static let colors: [Color] = [
        Color("shimmer_item").opacity(0.6),
        Color("shimmer_item").opacity(0.4),
        Color("shimmer_item").opacity(0.3),
    ]

    public func body(content: Content) -> some View {
        let leadingEndPoint: UnitPoint = startFromLeading ? .trailing : .leading
        let reverseEndPoint: UnitPoint = startFromLeading ? .leading : .trailing
        let endPoint: UnitPoint = viewModel.isAnimating ? leadingEndPoint : reverseEndPoint
        content
            .overlay {
                LinearGradient(
                    colors: viewModel.isAnimating ? ShimmerViewModifier.colors : [Color("shimmer_item").opacity(0.6)],
                    startPoint: startFromLeading ? .leading : .trailing,
                    endPoint: endPoint
                )
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))            
    }
}

public extension View {
    func shimmer(cornerRadius: CGFloat = 4, startFromLeading: Bool = true) -> some View {
        modifier(ShimmerViewModifier(cornerRadius: cornerRadius, startFromLeading: startFromLeading))
    }
}
