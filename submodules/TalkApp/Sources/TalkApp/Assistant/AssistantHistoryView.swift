//
//  AssistantHistoryView.swift
//  Talk
//
//  Created by hamed on 6/27/22.
//

import Chat
import Logger
import SwiftUI
import TalkExtensions
import TalkUI
import TalkViewModels

struct AssistantHistoryView: View {
    @StateObject var viewModel: AssistantHistoryViewModel = .init()

    var body: some View {
        List {
            ForEach(viewModel.histories) { action in
                AssistantActionRow(action: action)
                    .onAppear {
                        if action == viewModel.histories.last {
                            viewModel.loadMore()
                        }
                    }
            }
            .transition(.asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .trailing)))
        }
        .environmentObject(viewModel)
        .navigationTitle("Assistant.History.title")
        .animation(.easeInOut, value: viewModel.histories.count)
    }
}

struct AssistantActionRow: View {
    let action: AssistantAction

    var body: some View {
        HStack {
            ImageLoaderView(participant: action.participant)
                .frame(width: 28, height: 28)
                .background(.blue.opacity(0.8))
                .clipShape(RoundedRectangle(cornerRadius:(18)))
            
            VStack(alignment: .leading) {
                Text(action.participant?.name ?? "")
                    .font(Font.normal(.caption))
                Text(action.actionTime?.date.localFormattedTime ?? "")
                    .font(Font.bold(.caption))
                    .foregroundStyle(.secondary)
            }

            Spacer()
            Text(action.actionType?.stringValue ?? "unknown")
                .frame(width: 72)
                .font(Font.normal(.caption2))
                .padding(EdgeInsets(top: 2, leading: 6, bottom: 2, trailing: 6))
                .foregroundColor(action.actionType?.actionColor ?? .gray)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(action.actionType?.actionColor ?? .gray)
                )
            Image(systemName: action.actionType?.imageIconName ?? "questionmark.square")
                .resizable()
                .scaledToFit()
                .frame(width: 18, height: 18)
                .foregroundStyle(action.actionType?.actionColor ?? .gray)
        }
    }
}
