//
//  ThreeDotAnimation.swift
//  TalkUI
//
//  Created by Hamed Hosseini on 6/7/21.
//

import SwiftUI

struct ThreeDotAnimation: View {
    @State private var drawCount: Double = 0
    @State private var timer: Timer?

    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<Int(drawCount), id: \.self) { i in
                Circle()
                    .frame(width: 4, height: 4)
                    .transition(.asymmetric(insertion: .scale.combined(with: .opacity), removal: .scale).combined(with: .opacity))
                    .fixedSize()
                    .foregroundColor(Color.App.textSecondary)
                    .font(.fFootnote)
                    .padding(.horizontal, 3)
            }
            Spacer()
        }
        .task {
            timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { timer in
                if timer.isValid {
                    Task {
                        await handleTimer()
                    }
                }
            }
        }
        .animation(.easeInOut, value: drawCount)
        .onDisappear {
            timer?.invalidate()
            timer = nil
        }
    }
    
    private func handleTimer() {
        if drawCount == 3 {
            drawCount = 0
        } else {
            drawCount += 1
        }
    }
}
struct ThreeDotAnimation_Previews: PreviewProvider {
    static var previews: some View {
        ThreeDotAnimation()
    }
}
