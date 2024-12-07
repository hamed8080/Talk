//
//  ShimmerViewModel.swift
//
//
//  Created by hamed on 12/24/23.
//

import Foundation
import SwiftUI

@MainActor
public class ShimmerItemViewModel: ObservableObject {
    @Published public var isAnimating = false
}

@MainActor
public class ShimmerViewModel: ObservableObject {
    @Published public var isShowing = false
    private var timer: Timer?
    public var itemViewModel = ShimmerItemViewModel()
    private let delayToHide: TimeInterval
    private let repeatInterval: TimeInterval

    public init(delayToHide: TimeInterval = 0.2, repeatInterval: TimeInterval = 0.8) {
        self.delayToHide = delayToHide
        self.repeatInterval = repeatInterval
    }

    public func show() {
        Task {
            await MainActor.run {
                startTimer()
                withAnimation {
                    isShowing = true
                }
            }
        }
    }

    public func hide() {
        Task {
            if delayToHide != 0 {
                try? await Task.sleep(for: .seconds(0.2))
            }
            await MainActor.run {
                stopTimer()
                withAnimation {
                    isShowing = false
                }
            }
        }
    }

    public func startTimer() {
        timer?.invalidateTimer()
        timer = nil
        timer = Timer.scheduledTimer(withTimeInterval: repeatInterval, repeats: true) { [weak self] timer in
            if timer.isValid {
                Task { @MainActor [weak self] in
                    self?.handleTimer()
                }
            }
        }
    }
    
    private func handleTimer() {        
        withAnimation(.easeInOut) {
            itemViewModel.isAnimating.toggle()
        }
    }

    public func stopTimer() {
        timer?.invalidateTimer()
        timer = nil
    }
}
