//
//  ThreadImageView.swift
//  Talk
//
//  Created by hamed on 6/27/23.
//

import Chat
import ChatModels
import SwiftUI
import TalkUI
import TalkViewModels

struct ThreadImageView: View {
    @State var thread: Conversation
    let threadsVM: ThreadsViewModel
    @State private var computedImageURL: String?

    var body: some View {
        ZStack {
            if thread.type == .selfThread {
                Circle()
                    .foregroundColor(.clear)
                    .scaledToFit()
                    .frame(width: 54, height: 54)
                    .background(Color.App.gray5)
                    .clipShape(RoundedRectangle(cornerRadius:(24)))
                    .overlay {
                        Image("bookmark")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 27, height: 27)
                            .foregroundStyle(Color.App.text)
                    }
            } else if let image = computedImageURL {
                ImageLoaderView(imageLoader: threadsVM.avatars(for: image, metaData: image, userName: thread.title))
                    .id("\(computedImageURL ?? "")\(thread.id ?? 0)")
                    .font(.iransansBoldBody)
                    .foregroundColor(.white)
                    .frame(width: 54, height: 54)
                    .background(Color.App.blue.opacity(0.4))
                    .clipShape(RoundedRectangle(cornerRadius:(24)))
            } else {
                Text(verbatim: String(thread.computedTitle.trimmingCharacters(in: .whitespacesAndNewlines).first ?? " "))
                    .id("\(computedImageURL ?? "")\(thread.id ?? 0)")
                    .font(.iransansBoldBody)
                    .foregroundColor(.white)
                    .frame(width: 54, height: 54)
                    .background(Color.App.blue.opacity(0.4))
                    .clipShape(RoundedRectangle(cornerRadius:(24)))
            }
        }.task {
            /// We do this beacuse computedImageURL use metadata decoder and it should not be on the main thread.
            Task {
                computedImageURL = thread.computedImageURL
            }
        }
    }
}
