//
//  GalleyOffsetViewModel.swift
//  TalkViewModels
//
//  Created by hamed on 10/22/22.
//

import Foundation
import SwiftUI

@MainActor
public class GalleyOffsetViewModel: ObservableObject {
    @Published public var offset: CGSize = .zero
    @Published public var baseScale: CGFloat = 1.0
    @Published public var currentScale: CGFloat = 1.0
    @Published public var previousOffset: CGSize = .zero
    @Published public var isUIHidden = false
    private let maxScale: CGFloat = 4.0
    private let minScale: CGFloat = 1.0
    
    public init() {}
    
    public func dismiss() {
        DispatchQueue.main.async { [weak self] in
            AppState.shared.objectsContainer.appOverlayVM.isPresented = false
            AppState.shared.objectsContainer.appOverlayVM.clear()
            self?.resetZoom()
        }
    }
    
    public var totalScale: CGFloat {
        (baseScale * currentScale).clamped(to: minScale...maxScale)
    }
    
    public func onMagnifyChanged(scale: CGFloat) {
        currentScale = scale
    }

    public func onMagnifyEnded(scale: CGFloat) {
        baseScale = (baseScale * scale).clamped(to: minScale...maxScale)
        currentScale = 1.0
    }

    public func onDragChanged(translation: CGSize) {
        guard baseScale > 1.0 else { return }
        isUIHidden = true
        offset = CGSize(width: previousOffset.width + translation.width,
                        height: previousOffset.height + translation.height)
    }

    public func onDragEnded(translation: CGSize) {
        guard baseScale > 1.0 else { return }
        isUIHidden = true
        previousOffset = offset
    }
    
    public func onVerticalDismissChanged(translation: CGSize) {
        if abs(translation.width) < 10 && abs(translation.height) > abs(translation.width) {
            // Optional: Add visual feedback like offsetting the image down
            self.offset = CGSize(width: 0, height: translation.height)
        }
    }

    public func onVerticalDismissEnded(translation: CGSize, velocity: CGSize) {
        if abs(velocity.height) > 30,
           abs(translation.width) < 40,
           abs(translation.height) > abs(translation.width),
           translation.height > 80 {
            dismiss()
        } else {
            resetOffset()
        }
    }

    public func toggleZoom(at location: CGPoint, in size: CGSize) {
        if baseScale == 1 {
            baseScale = 2
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            offset = CGSize(width: (center.x - location.x), height: (center.y - location.y))
            previousOffset = offset
            isUIHidden = true
        } else {
            resetZoom()
        }
    }

    public func resetZoom() {
        baseScale = 1.0
        currentScale = 1.0
        offset = .zero
        previousOffset = .zero
    }
    
    private func resetOffset() {
        withAnimation {
            self.offset = .zero
        }
    }

    public func toggleUI() {
        isUIHidden.toggle()
    }
}

extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        min(max(self, limits.lowerBound), limits.upperBound)
    }
}
