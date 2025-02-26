//
//  SwingLoadingIndicator.swift
//  TalkUI
//
//  Created by hamed on 2/20/22.
//

import Foundation
import SwiftUI

public struct SwingLoadingIndicator: View {
    @State private var width: CGFloat = 400
    @State private var indicatorWidth: CGFloat
    @State private var x: CGFloat
    private let startXPosition: CGFloat
    @State private var endXPosition: CGFloat
    private let duration: TimeInterval = 2.0
    private let delayToReset: TimeInterval = 0.01
    @State private var onAniamtionCompletionTimer: Timer?
    @State private var delayTimer: Timer?

    public init(width: CGFloat = 400, indicatorWidth: CGFloat = 400) {
        self.indicatorWidth = indicatorWidth
        self.startXPosition = -indicatorWidth
        self.endXPosition = width + indicatorWidth
        self.width = width
        self.x = -indicatorWidth
    }

    public var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.App.bgSecondary)
                .frame(height: 1.5)
                .frame(minWidth: 0, maxWidth: .infinity)

            RoundedRectangle(cornerRadius: 0.5)
                .fill(Color.App.accent)
                .frame(width: indicatorWidth, height: 1)
                .position(x: x)
        }
        .frame(height: 1.5)
        .background(widthReader)
        .onAppear {
            startAnimation()
        }
        .onDisappear {
            invalidateTimers()
        }
    }

    private func startAnimation() {
        withAnimation(.easeInOut(duration: duration)) {
            if x == endXPosition {
                x = -indicatorWidth
            } else {
                x = endXPosition
                indicatorWidth = indicatorWidth * 0.1
            }
        }
        onAniamtionCompletionTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { _ in
            Task {
                await handleStartTimer()
            }
        }
    }

    private var widthReader: some View {
        GeometryReader { reader in
            Color.clear.onAppear {
                width = reader.size.width
                self.endXPosition = width + indicatorWidth
            }
        }
    }

    private func invalidateTimers() {
        onAniamtionCompletionTimer?.invalidate()
        onAniamtionCompletionTimer = nil
        delayTimer?.invalidate()
        delayTimer = nil
    }
    
    private func handleStartTimer() {
        x = startXPosition
        indicatorWidth = 400 * 1.2
        delayTimer = Timer.scheduledTimer(withTimeInterval: delayToReset, repeats: false) { _ in
            Task {
                await startAnimation()
            }
        }
    }
}
