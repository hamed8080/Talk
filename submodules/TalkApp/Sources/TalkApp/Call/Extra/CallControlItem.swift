//
//  CallControlItem.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import SwiftUI
import AdditiveUI

struct CallControlItem: View {
    var iconSfSymbolName: String
    var subtitle: String
    var color: Color?
    var vertical: Bool = false
    var action: (() -> Void)?
    @State var isActive = false

    var body: some View {
        Button(action: {
            isActive.toggle()
            action?()
        }, label: {
            if vertical {
                HStack {
                    content
                }
            } else {
                VStack {
                    content
                }
            }
        })
        .buttonStyle(DeepButtonStyle(backgroundColor: Color.clear, shadow: 0, cornerRadius: 0))
    }

    @ViewBuilder var content: some View {
        Circle()
            .fill(color ?? .blue)
            .overlay(
                Image(systemName: iconSfSymbolName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundColor(.white)
                    .padding(2)
            )
            .frame(width: 52, height: 52)
        if !subtitle.isEmpty {
            Text(subtitle)
                .fontWeight(.bold)
                .font(.system(size: 10))
                .fixedSize()
        }
    }
}
