//
//  CenterArriveStickerView.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import SwiftUI

struct CenterArriveStickerView: View {
    @EnvironmentObject var viewModel: CallViewModel
    @State var animate = false

    var body: some View {
        if let sticker = viewModel.newSticker {
            HStack(spacing: 4) {
                Text(sticker.participant.name ?? "")
                    .font(.caption2)
                sticker.sticker.systemImage
                    .resizable()
                    .scaledToFit()
                    .frame(width: 48, height: 48)
                    .foregroundColor(.yellow)
                    .scaleEffect(x: animate ? 1 : 0.8, y: animate ? 1 : 0.8)
                    .animation(.easeInOut, value: viewModel.newSticker != nil)
                    .transition(.scale)
                    .onAppear {
                        withAnimation(.spring().repeatForever(autoreverses: true)) {
                            animate.toggle()
                        }
                    }
            }
        }
    }
}
