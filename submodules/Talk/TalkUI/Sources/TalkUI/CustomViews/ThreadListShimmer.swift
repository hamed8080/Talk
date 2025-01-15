//
//  ThreadListShimmer.swift
//  TalkUI
//
//  Created by hamed on 2/15/24.
//

import SwiftUI
import TalkViewModels

public struct ThreadListShimmer: View {
    @EnvironmentObject var viewModel: ShimmerViewModel
    public init(){}

    public var body: some View {
        if viewModel.isShowing {
            List {
                ForEach(1...20, id: \.self) { id in
                    ThreadRowShimmer()
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                }
            }
            .environmentObject(viewModel.itemViewModel)
            .listStyle(.plain)
            .background(Color.App.bgPrimary)
            .transition(.opacity)
        }
    }
}

struct ThreadRowShimmer: View {
    private let isUnreadCount: Bool = Bool.random()
    let color: Color = Color.App.textSecondary.opacity(0.5)

    init(){}

    var body: some View {
        HStack(spacing: 16) {
            /// Thread image view
            Rectangle()
                .fill(color)
                .frame(width: 54, height: 54)
                .clipShape(RoundedRectangle(cornerRadius:(24)))
                .shimmer(cornerRadius: 24)

            VStack(alignment: .leading, spacing: 6) {

                HStack {
                    /// Thread type icon
                    Rectangle()
                        .fill(color)
                        .frame(width: 12, height: 12)
                        .shimmer(cornerRadius: 6)

                    /// Thread title
                    Rectangle()
                        .fill(color)
                        .frame(height: 12)
                        .shimmer(cornerRadius: 6)

                    /// Thread mute
                    Rectangle()
                        .fill(color)
                        .frame(height: 12)
                        .shimmer(cornerRadius: 6)
                }

                HStack {
                    /// Thread last message
                    Rectangle()
                        .fill(color)
                        .frame(height: 14)
                        .clipShape(RoundedRectangle(cornerRadius:(7)))
                        .shimmer(cornerRadius: 7)

                    /// Thread unread count
                    if isUnreadCount {
                        Rectangle()
                            .fill(color)
                            .frame(width: 24, height: 24)
                            .clipShape(RoundedRectangle(cornerRadius:(12)))
                            .shimmer(cornerRadius: 12)
                    }
                }
            }
        }
        .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 8))
    }
}

struct ThreadListShimmer_Previews: PreviewProvider {
    static var previews: some View {
        ThreadListShimmer()
            .environmentObject(ShimmerViewModel())
    }
}
