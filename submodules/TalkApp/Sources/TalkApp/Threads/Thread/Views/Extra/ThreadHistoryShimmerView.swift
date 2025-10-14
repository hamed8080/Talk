//
//  ThreadHistoryShimmerView.swift
//  Talk
//
//  Created by hamed on 2/15/24.
//

import SwiftUI
import TalkViewModels
import TalkUI

struct ThreadHistoryShimmerView: View {
    @State private var viewModel: ShimmerViewModel = .init()
//    @EnvironmentObject var historyVM: ThreadHistoryViewModel

    var body: some View {
        if viewModel.isShowing {
            ScrollViewReader { reader in
                ScrollView {
                    LazyVStack {
                        ForEach(1...10, id: \.self) { id in
                            MessageRowShimmer(id: id)
                                .listRowSeparator(.hidden)
                                .listRowInsets(.zero)
                                .listRowBackground(Color.clear)
                        }
                    }
                }
                .padding(.bottom, ConstantSizes.bottomToolbarSize)
                .environmentObject(viewModel.itemViewModel)
                .listStyle(.plain)
                .background(ThreadbackgroundView(threadId: 0))
                .transition(.opacity)
                .onAppear() {
                    reader.scrollTo(10, anchor: .bottom)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        reader.scrollTo(10, anchor: .bottom)
                    }
                }
            }
//            .onReceive(historyVM.objectWillChange) { _ in
//                Task {
//                    viewModel = await historyVM.shimmerViewModel
//                }
//            }
//            .task {
//                viewModel = await historyVM.shimmerViewModel
//            }
        } else {
//            EmptyView()
//                .onReceive(historyVM.objectWillChange) { _ in
//                Task {
//                    viewModel = await historyVM.shimmerViewModel
//                }
//            }
        }
    }
}

struct MessageRowShimmer: View {
    private let id: Int
    private let width: CGFloat
    private let isMe: Bool
    private let isSameUserMessage: Bool
    let color: Color = Color.App.textSecondary.opacity(0.5)
    let isImage: Bool = Bool.random()

    public init(id: Int, width: CGFloat? = nil, isMe: Bool? = nil) {
        self.id = id
        self.width = width ?? CGFloat.random(in: (128...ThreadViewModel.maxAllowedWidth))
        self.isMe = isMe ?? Bool.random()
        isSameUserMessage = Bool.random()
    }

    var body: some View {
        HStack(spacing: 0) {

            if isMe {
                Spacer()
            }

            VStack(spacing: 0) {
                Spacer()
                /// Avatar
                if !isMe && !isSameUserMessage {
                    Rectangle()
                        .fill(color)
                        .frame(width: ConstantSizes.messageAvatarViewSize, height: ConstantSizes.messageAvatarViewSize)
                        .clipShape(RoundedRectangle(cornerRadius:(ConstantSizes.messageAvatarViewSize / 2)))
                        .shimmer(cornerRadius: ConstantSizes.messageAvatarViewSize / 2, startFromLeading: !isMe)
                        .padding(.trailing, 2)
                } else {
                    /// Empty avatar
                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: ConstantSizes.messageAvatarViewSize, height: ConstantSizes.messageAvatarViewSize)
                        .padding(.trailing, 2)
                }
            }

            HStack {
                VStack(alignment: isMe ? .trailing : .leading, spacing: 0) {
                    // Image view
                    if isImage {
                        Rectangle()
                            .fill(color)
                            .frame(width: width, height: CGFloat.random(in: 64...196))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                            .shimmer(cornerRadius: 6, startFromLeading: !isMe)
                            .padding(.bottom, 8)
                    }

                    /// Group ParticipantName
                    Rectangle()
                        .fill(color)
                        .frame(width: CGFloat.random(in: 128...width), height: 14)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .shimmer(startFromLeading: !isMe)

                    //// Text Message view
                    ForEach(1...Int.random(in: 1...3), id: \.self) { id in
                        Rectangle()
                            .foregroundColor(color)
                            .frame(width: CGFloat.random(in: 128...width), height: 8)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                            .shimmer(cornerRadius: 2, startFromLeading: !isMe)
                            .padding(.top, 8)
                    }

                    /// Footer View
                    HStack {
                        // Time
                        Rectangle()
                            .fill(color)
                            .frame(width: 64, height: 12)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                            .shimmer(startFromLeading: !isMe)

                        /// Image status
                        Rectangle()
                            .fill(color)
                            .frame(width: 12, height: 12)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                            .shimmer(cornerRadius: 4, startFromLeading: !isMe)
                    }
                    .padding(.top, 10)
                }
                .padding(4)
                .padding(isMe ? .trailing : .leading, 6) /// For tail                
            }
            .frame(minWidth: 128, maxWidth: width, alignment: isMe ? .trailing : .leading)

            if !isMe {
                Spacer()
            }
        }
        .padding(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
    }
}

struct ThreadHistoryShimmerView_Previews: PreviewProvider {
    static var previews: some View {
        ThreadHistoryShimmerView()
            .environmentObject(viewModel)
    }

    static var viewModel: ShimmerViewModel {
        let viewModel = ShimmerViewModel()
        ThreadViewModel.maxAllowedWidth = 256
        return viewModel
    }
}
