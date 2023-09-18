//
//  SelectThreadContentList.swift
//  Talk
//
//  Created by Hamed Hosseini on 6/5/21.
//

import AdditiveUI
import Chat
import ChatModels
import SwiftUI
import TalkUI
import TalkViewModels

struct SelectThreadContentList: View {
    @EnvironmentObject var viewModel: ThreadsViewModel
    @State var searechInsideThread: String = ""
    var onSelect: (Conversation) -> Void
    @Environment(\.dismiss) var dismiss

    var body: some View {
        Form {
            SectionTitleView(title: "Thread.selectToStartConversation")
            Section {
                MultilineTextField("General.searchHere", text: $searechInsideThread, backgroundColor: Color.gray.opacity(0.2))
                    .cornerRadius(16)
                    .noSeparators()
                    .onChange(of: searechInsideThread) { _ in
                        viewModel.searchInsideAllThreads(text: searechInsideThread)
                    }
            }
            .listRowBackground(Color.clear)

            Section {
                List {
                    ForEach(viewModel.filtered) { thread in
                        SelectThreadRow(thread: thread)
                            .onTapGesture {
                                onSelect(thread)
                                dismiss()
                            }
                            .onAppear {
                                if viewModel.filtered.last == thread {
                                    viewModel.loadMore()
                                }
                            }
                    }
                }
            }
        }
    }
}

struct SelectThreadContentList_Previews: PreviewProvider {
    static var previews: some View {
        let appState = AppState.shared
        let vm = ThreadsViewModel()
        SelectThreadContentList { _ in
        }
        .onAppear {}
        .environmentObject(vm)
        .environmentObject(appState)
    }
}