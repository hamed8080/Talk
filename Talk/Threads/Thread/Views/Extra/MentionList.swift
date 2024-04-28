//
//  MentionList.swift
//  Talk
//
//  Created by hamed on 3/13/23.
//

import SwiftUI
import TalkViewModels
import TalkUI
import TalkExtensions
import ChatModels

@MainActor
struct MentionList: View {
    @EnvironmentObject var threadVM: ThreadViewModel
    @EnvironmentObject var viewModel: MentionListPickerViewModel

    var body: some View {
        if viewModel.mentionList.count > 0 {
            List {
                ForEach(viewModel.mentionList) { participant in
                    mentionParticipantRow(participant)
                }

                ListLoadingView(isLoading: .constant(viewModel.lazyList.isLoading))
                    .listRowSeparator(.hidden)
                    .listRowInsets(.zero)
                    .listRowBackground(Color.clear)
                    .animation(.easeInOut, value: viewModel.lazyList.isLoading)
                    .frame(height: viewModel.lazyList.isLoading ? 24 : 0)
                    .id(-3)
            }
            .listStyle(.plain)
            .environment(\.defaultMinListRowHeight, 0)
            .transition(.asymmetric(insertion: .opacity, removal: .move(edge: .bottom)))
            .frame(maxHeight: min(196, CGFloat(viewModel.mentionList.count) * 48))
            .animation(.easeInOut, value: viewModel.mentionList.count)
        } else {
            EmptyView()
        }
    }

    @ViewBuilder
    private func mentionParticipantRow(_ participant: Participant) -> some View {
        HStack {
            let config = ImageLoaderConfig(url: participant.image ?? "", userName: String.splitedCharacter(participant.name ?? participant.username ?? ""))
            ImageLoaderView(imageLoader: .init(config: config))
                .id("\(participant.image ?? "")\(participant.id ?? 0)")
                .font(.iransansBoldBody)
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(String.getMaterialColorByCharCode(str: participant.name ?? participant.username ?? ""))
                .clipShape(RoundedRectangle(cornerRadius:(16)))
            Text(participant.contactName ?? participant.name ?? "\(participant.firstName ?? "") \(participant.lastName ?? "")")
                .font(.iransansCaption)
                .fontWeight(.medium)
            Spacer()
        }
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
        .listRowInsets(.init(top: 4, leading: 4, bottom: 8, trailing: 4))
        .onAppear {
            if participant == viewModel.mentionList.last {
                Task {
                    await viewModel.loadMore()
                }
            }
        }
        .onTapGesture {
            threadVM.sendContainerViewModel.addMention(participant)
            threadVM.animateObjectWillChange()
        }
    }
}

struct MentionList_Previews: PreviewProvider {
    static var previews: some View {
        MentionList()
    }
}
