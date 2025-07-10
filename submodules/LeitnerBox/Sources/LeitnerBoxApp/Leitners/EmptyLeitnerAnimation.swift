//
//  EmptyLeitnerAnimation.swift
//  LeitnerBox
//
//  Created by hamed on 10/10/24.
//

import SwiftUI

struct EmptyLeitnerAnimation: View {
    @EnvironmentObject var viewModel: LeitnerViewModel

    var body: some View {
        ZStack {
            GradientAnimationView()
            ZStack {
                VStack {
                    if #available(macOS 15.0, iOS 18.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *) {
                        ios18EmptyTrayBreathAnimation
                    } else {
                        normalEmptyTrayBreathAnimation
                    }
                    Text(makeAttributedString())
                        .font(.system(.headline, design: .rounded))
                        .multilineTextAlignment(.center)
                }
            }
            .frame(width: 256, height: 256)
            .background(.ultraThickMaterial)
            .cornerRadius(24)
        }
        .frame(width: 256, height: 256)
        .cornerRadius(24)
        .onTapGesture {
            viewModel.showEditOrAddLeitnerAlert.toggle()
        }
    }
    
    @available(macOS 15.0, iOS 18.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
    private var ios18EmptyTrayBreathAnimation: some View {
        Image(systemName: "tray")
            .resizable()
            .scaledToFit()
            .foregroundStyle(Color.accentColor)
            .frame(width: 64, height: 64)
            .symbolEffect(.breathe)
    }
    
    private var normalEmptyTrayBreathAnimation: some View {
        Image(systemName: "tray")
            .resizable()
            .scaledToFit()
            .foregroundStyle(Color.accentColor)
            .frame(width: 64, height: 64)
    }
    
    private func makeAttributedString() -> AttributedString {
        var attributedString = AttributedString("Leitner is empty.\nTap to add new Leitner.")
        attributedString.foregroundColor = .gray // Default color for other text
        // Find "Tap" and change its color to orange
        if let range = attributedString.range(of: "Tap") {
            attributedString[range].foregroundColor = .orange
        }
        return attributedString
    }
}

private struct GradientAnimationView: View {
    @State var isAnimating: Bool = false
    @State private var progress: CGFloat = 0
    
    var body: some View {
        Rectangle()
            .animatableGradient(from: [.purple, .green], toColor: [.yellow, .red], progress: progress)
            .opacity(0.8)
            .task {
                withAnimation(.easeOut(duration: 5).repeatForever(autoreverses: true)) {
                    isAnimating = true
                    progress = 1
                }
            }
    }
}

#Preview {
    EmptyLeitnerAnimation()
        .environmentObject(LeitnerViewModel(viewContext: PersistenceController.shared.viewContext))
}
