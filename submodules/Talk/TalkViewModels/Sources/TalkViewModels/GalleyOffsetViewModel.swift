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
    @Published public var endScale: CGFloat = 1.0
    @Published public var isDragging = false
    @Published public var dragOffset: CGSize = .zero
    @Published public var containerYOffset: CGFloat = .zero
    @Published public var previousDragOffset: CGSize = .zero
    public weak var appOverlayVM: AppOverlayViewModel?
    @Published public var heightOfScreen: CGFloat = .zero
    
    public func onDragChanged(_ value: DragGesture.Value, forcedLeftToRight: Bool) {
        isDragging = true
        if endScale > 1 {
            scrollInZoomMode(value, forcedLeftToRight: forcedLeftToRight)
        }
    }
    
    public func onDragEnded(_ value: DragGesture.Value) {
        isDragging = false
        previousDragOffset = dragOffset
        
        if value.translation.height < 100, endScale <= 1 {
            resetOffset()
        } else if value.translation.height > 100, endScale == 1 {
            dragOffset.height = value.translation.height
            dismiss()
        }
    }
    
    public func onContainerDragChanged(_ value: DragGesture.Value) {
        if value.translation.height > 0, endScale == 1 {
            containerYOffset = value.translation.height
        }
    }
    
    public func onContainerDragEnded(_ endValue: DragGesture.Value) {
        if endValue.translation.height > 100, endScale == 1 {
            containerYOffset = endValue.translation.height
            dismiss()
        } else if endScale == 1 {
            resetOffset()
        }
    }
    
    public func onDoubleTapped() {
        withAnimation(.easeOut) {
            if endScale == 1 {
                doubleZoom()
            } else {
                resetZoom()
                resetOffset()
            }
        }
    }
    
    public func onMagnificationEnded(_ value: GestureStateGesture<MagnificationGesture, CGFloat>.Value) {
        if isDragging { return }
        endScale = value
    }
    
    private func scrollInZoomMode(_ value: DragGesture.Value, forcedLeftToRight: Bool) {
        var width: CGFloat = 0
        if !forcedLeftToRight {
            width = -value.translation.width + previousDragOffset.width
        } else {
            width = value.translation.width + previousDragOffset.width
        }
        let height = value.translation.height + previousDragOffset.height
        dragOffset = .init(width: width, height: height)
    }
    
    private func doubleZoom() {
        endScale = 2
    }
    
    private func resetZoom() {
        endScale = 1
    }
    
    private func resetOffset() {
        containerYOffset = .zero
        dragOffset = .zero
        previousDragOffset = .zero
    }
    
    public func dismiss() {
        if #available(iOS 17.0, *) {
            withAnimation(.easeInOut(duration: 0.3)) {
                dragOffset.height += heightOfScreen - dragOffset.height
                containerYOffset += dragOffset.height
            } completion: {
                DispatchQueue.main.async { [weak self] in
                    self?.appOverlayVM?.isPresented = false
                    self?.appOverlayVM?.clear()
                    self?.resetZoom()
                    self?.resetOffset()
                }
            }
        } else {
            withAnimation(.easeInOut(duration: 0.3)) {
                dragOffset.height += heightOfScreen - dragOffset.height
                containerYOffset = dragOffset.height
                DispatchQueue.main.async { [weak self] in
                    self?.appOverlayVM?.isPresented = false
                    self?.appOverlayVM?.clear()
                    self?.resetZoom()
                    self?.resetOffset()
                }
            }
        }
    }
}
