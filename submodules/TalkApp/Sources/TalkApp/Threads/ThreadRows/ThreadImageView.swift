//
//  ThreadImageView.swift
//  Talk
//
//  Created by hamed on 6/27/23.
//

import Chat
import SwiftUI
import TalkUI
import TalkViewModels
import TalkModels

struct ThreadImageView: View {
    @EnvironmentObject var thread: CalculatedConversation

    var body: some View {
        ZStack {
            if thread.type == .selfThread {
                SelfThreadImageView(imageSize: 54, iconSize: 27)
            } else if
                let image = thread.computedImageURL,
                let imageVM = thread.imageLoader as? ImageLoaderViewModel
            {
                ImageLoaderView(
                    imageLoader: imageVM,
                    textFont: .fBoldBody
                )
                .id("\(thread.computedImageURL ?? "")\(thread.id ?? 0)")
                .font(.fBoldBody)
                .foregroundColor(.white)
                .frame(width: 54, height: 54)
                .background(Color(uiColor: thread.materialBackground))
                .clipShape(RoundedRectangle(cornerRadius:(24)))
            } else {
                Text(verbatim: thread.splitedTitle)
                    .id("\(thread.computedImageURL ?? "")\(thread.id ?? 0)")
                    .font(.fBoldSubheadline)
                    .foregroundColor(.white)
                    .frame(width: 54, height: 54)
                    .background(Color(uiColor: thread.materialBackground))
                    .clipShape(RoundedRectangle(cornerRadius:(24)))
            }
        }
    }
}

struct SelfThreadImageView: View {
    let imageSize: CGFloat
    let iconSize: CGFloat
    var body: some View {
        let startColor = Color(red: 255/255, green: 145/255, blue: 98/255)
        let endColor = Color(red: 255/255, green: 90/255, blue: 113/255)
        Circle()
            .foregroundColor(.clear)
            .scaledToFit()
            .frame(width: imageSize, height: imageSize)
            .background(LinearGradient(colors: [startColor, endColor], startPoint: .top, endPoint: .bottom))
            .clipShape(RoundedRectangle(cornerRadius:((imageSize / 2) - 3)))
            .overlay {
                Image("bookmark")
                    .resizable()
                    .scaledToFit()
                    .frame(width: iconSize, height: iconSize)
                    .foregroundStyle(Color.App.textPrimary)
            }
    }
}
