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

struct ThreadImageView: View {
    @State var thread: Conversation
    let threadsVM: ThreadsViewModel
    @State private var computedImageURL: String?
    @State var splitedTitle = ""
    @State var materialBackground: UIColor = .clear

    var body: some View {
        ZStack {
            if thread.type == .selfThread {
                SelfThreadImageView(imageSize: 54, iconSize: 27)
            } else if let image = computedImageURL {
                ImageLoaderView(
                    imageLoader: threadsVM.avatars(for: image, metaData: thread.metadata, userName: splitedTitle),
                    textFont: .iransansBoldBody
                )
                .id("\(computedImageURL ?? "")\(thread.id ?? 0)")
                .font(.iransansBoldBody)
                .foregroundColor(.white)
                .frame(width: 54, height: 54)
                .background(Color(uiColor: materialBackground))
                .clipShape(RoundedRectangle(cornerRadius:(24)))
            } else {
                Text(verbatim: splitedTitle)
                    .id("\(computedImageURL ?? "")\(thread.id ?? 0)")
                    .font(.iransansBoldSubheadline)
                    .foregroundColor(.white)
                    .frame(width: 54, height: 54)
                    .background(Color(uiColor: materialBackground))
                    .clipShape(RoundedRectangle(cornerRadius:(24)))
            }
        }.task {
            /// We do this beacuse computedImageURL use metadata decoder and it should not be on the main thread.
            await calculate()
        }
//        .onReceive(thread.objectWillChange) { _ in /// update an image of a thread by another device
//            if computedImageURL != self.thread.computedImageURL {
//                self.computedImageURL = thread.computedImageURL
//            }
//            Task {
//                await calculate()
//            }
//        }
    }

    private func calculate() async {
        let materialBackground = String.getMaterialColorByCharCode(str: thread.title ?? "")
        let splitedTitle = String.splitedCharacter(thread.computedTitle)
        let computedImageURL = thread.computedImageURL
        await MainActor.run {
            self.materialBackground = materialBackground
            self.splitedTitle = splitedTitle
            self.computedImageURL = computedImageURL
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
