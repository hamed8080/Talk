//
//  AddThreadToTagsView.swift
//  Talk
//
//  Created by Hamed Hosseini on 6/5/21.
//

import AdditiveUI
import Chat
import SwiftUI
import TalkUI
import TalkViewModels

struct AddThreadToTagsView: View {
    typealias Tag = ChatModels.Tag
    @StateObject var viewModel: TagsViewModel
    @State var showAddNewFolderDialog = false
    var onCompleted: (Tag) -> Void
    @State var tagName: String = ""

    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.tags) { tag in
                    TagRow(tag: tag, viewModel: viewModel)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                viewModel.deleteTag(tag)
                            } label: {
                                Label("General.delete", systemImage: "trash")
                            }
                            .background(Color.App.red)
                        }
                }
            }
            .listStyle(.plain)
            .padding(0)
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("Tags.addToFolder")
            .customDialog(isShowing: $showAddNewFolderDialog) {
                PrimaryCustomDialog(title: "Tags.addNewFolder",
                                    message: "Tags.addNewFolderSubtitle",
                                    systemImageName: "folder.badge.plus",
                                    textBinding: $tagName,
                                    hideDialog: $showAddNewFolderDialog,
                                    textPlaceholder: "Tags.enterNewFolderName",
                                    bundle: Language.preferedBundle) { _ in
                    viewModel.createTag(name: tagName)
                }
                .keyboardResponsive()
                .padding()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        withAnimation {
                            if let tag = viewModel.selectedTag {
                                onCompleted(tag)
                            }
                        }
                    } label: {
                        Label("General.done", systemImage: "square.and.arrow.down")
                    }
                }

                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        withAnimation {
                            showAddNewFolderDialog.toggle()
                        }
                    } label: {
                        Label("General.add", systemImage: "folder.badge.plus")
                    }
                }

                ToolbarItem(placement: .principal) {
                    ConnectionStatusToolbar()
                }
            }
            .onAppear {
                viewModel.getTagList()
            }
        }
    }
}

struct AddThreadToTags_Previews: PreviewProvider {
    static var previews: some View {
        let appState = AppState.shared
        let vm = TagsViewModel()
        AddThreadToTagsView(viewModel: vm) { _ in
        }
        .environmentObject(appState)
    }
}
