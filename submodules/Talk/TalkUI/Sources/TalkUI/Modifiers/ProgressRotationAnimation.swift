//
//  ProgressRotationAnimation.swift
//  Talk
//
//  Created by hamed on 2/6/24.
//

import SwiftUI

public struct ProgressRotationAnimation: ViewModifier {
    @State private var degree: Double = 0
    @State private var timer: Timer?
    @Binding var pause: Bool
    
    public init(pause: Binding<Bool>) {
        self._pause = pause
    }
    
    public func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(degree))
            .onAppear {
                updateAnimation()
            }
            .onChange(of: pause) { _ in
                updateAnimation()
            }
            .onDisappear {
                stopAnimation()
            }
    }
    
    private func updateAnimation() {
        if pause {
            stopAnimation()
        } else {
            reverseAnimation()
            scheduleAnimation()
        }
    }
    
    private func scheduleAnimation() {
        stopAnimation()
        timer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { timer in
            let isValid = timer.isValid
            Task {
                await handleTimer(isValid)
            }
        }
    }
    
    private func handleTimer(_ isValid: Bool) {
        if isValid {
            reverseAnimation()
        } else {
            stopAnimation()
        }
    }
    
    func reverseAnimation() {
        DispatchQueue.main.async {
            withAnimation(.easeInOut(duration: 2)) {
                degree += 360
            }
        }
    }
    
    func stopAnimation() {
        timer?.invalidate()
        timer = nil
    }
}

public extension View {
    func rotateAnimtion(pause: Binding<Bool>) -> some View {
        modifier(ProgressRotationAnimation(pause: pause))
    }
}
