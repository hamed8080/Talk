//
//  RotationDotsLoading.swift
//  TalkUI
//
//  Created by Hamed Hosseini on 9/13/25.
//

import SwiftUI

public struct RotationDotsLoading: View {
    let dotSize: CGFloat
    let distance: CGFloat
    @State private var rotation: Double = 0
    private let circleCount: Int
    private let rotationCount: Int
    
    public init(
        circleCount: Int = 9,
        rotationCount: Int = 6,
        dotSize: CGFloat = 12,
        distance: CGFloat = 40,
        rotation: Double = 0
    ) {
        self.dotSize = dotSize
        self.distance = distance
        self.rotation = rotation
        self.circleCount = circleCount
        self.rotationCount = rotationCount
    }
    
    public var body: some View {
        ZStack {
            ForEach(0..<circleCount, id: \.self) { index in
                Circle()
                    .fill(Color.white)
                    .frame(width: dotSize, height: dotSize)
                    .opacity(0.1)
                    .offset(y: -distance) // distance from center
                    .rotationEffect(.degrees((Double(index) / Double(circleCount)) * 360))
            }
            
            ForEach(0..<rotationCount, id: \.self) { index in
                Circle()
                    .fill(Color.white)
                    .frame(width: dotSize, height: dotSize)
                    .opacity(opacity(for: index))
                    .offset(y: -distance) // distance from center
                    .rotationEffect(.degrees((Double(index) / Double(rotationCount)) * 180))
            }
            .rotationEffect(.degrees(rotation))
        }
        
        .onAppear {
            withAnimation(
                Animation.linear(duration: 1.5)
                    .repeatForever(autoreverses: false)
            ) {
                rotation = 360
            }
        }
    }
    
    private func opacity(for index: Int) -> Double {
        // Creates a gradient effect — one fully opaque, others fade
        let step = Double(index) / Double(rotationCount)
        return step < 0.1 ? 0.1 : step
    }
}

struct ContentView: View {
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            RotationDotsLoading()
                .frame(width: 96, height: 96)
                .background(
                    Color.gray.opacity(0.3)
                        .cornerRadius(36, corners: .allCorners)
                )
        }
    }
}

#Preview {
    ContentView()
}
