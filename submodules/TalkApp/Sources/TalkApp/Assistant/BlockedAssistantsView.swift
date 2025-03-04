//
//  BlockedAssistantsView.swift
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

struct BlockedAssistantsView: View {
    @EnvironmentObject var viewModel: AssistantViewModel

    var body: some View {
        List {
            ForEach(viewModel.blockedAssistants) { blockedAssistant in
                AssistantRow(assistant: blockedAssistant)
            }
            .transition(.asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .trailing)))
        }
        .navigationTitle("Assistant.blockedList")
        .animation(.easeInOut, value: viewModel.blockedAssistants.count)
        .task {
            viewModel.blockedList()
        }
    }
}
