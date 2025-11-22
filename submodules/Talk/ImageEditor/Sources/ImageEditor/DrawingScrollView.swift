//
// DrawingScrollView.swift
// Copyright (c) 2022 ImageEditor
//
// Created by Hamed Hosseini on 12/14/22

import UIKit

/// A scroll view that allows one-finger drawing and two-finger scrolling/zooming simultaneously.
final class DrawingScrollView: UIScrollView, UIGestureRecognizerDelegate {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        // Allow multiple gesture recognizers (pinch + pan + custom draw)
        self.panGestureRecognizer.minimumNumberOfTouches = 1
        self.pinchGestureRecognizer?.delegate = self
        self.panGestureRecognizer.delegate = self
    }
    
    public func setMinimumNumberOfTouchesPanGesture(_ number: Int) {
        self.panGestureRecognizer.minimumNumberOfTouches = number
    }
    
    // Allow gestures to work simultaneously (scroll + draw)
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

