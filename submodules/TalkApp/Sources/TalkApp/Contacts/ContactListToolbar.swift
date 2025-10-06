//
//  ContactListToolbar.swift
//  Talk
//
//  Created by hamed on 12/13/23.
//

import SwiftUI
import TalkModels
import TalkViewModels
import TalkUI

struct ContactListToolbar: View {
    @State var isInSearchMode: Bool = false
    @EnvironmentObject var viewModel: ContactsViewModel

    var body: some View {
        VStack(spacing: 0) {
            ToolbarView(
                searchId: "Tab.contacts",
                title: "Tab.contacts",
                leadingViews: leadingViews,
                centerViews: centerViews,
                trailingViews: trailingViews
            )
            ContactListSearchBarFilterView(isInSearchMode: $isInSearchMode)
                .background(MixMaterialBackground())
                .environmentObject(viewModel)
        }
    }

    @ViewBuilder var centerViews: some View {
        ConnectionStatusToolbar()
    }

    @ViewBuilder var trailingViews: some View {
        EmptyView()
    }

    @ViewBuilder var searchButton: some View {
        if isInSearchMode {
            Button {
                AppState.shared.objectsContainer.contactsVM.searchContactString = ""
                AppState.shared.objectsContainer.searchVM.searchText = ""
                isInSearchMode.toggle()
            } label: {
                Image(systemName: "xmark")
                    .resizable()
                    .scaledToFit()
                    .padding(14)
                    .frame(width: ToolbarButtonItem.buttonWidth, height: ToolbarButtonItem.buttonWidth)
                    .foregroundStyle(Color.App.toolbarButton)
            }
            .buttonStyle(.borderless)
            .frame(minWidth: 0, minHeight: 0, maxHeight: isInSearchMode ? ToolbarButtonItem.buttonWidth : 0)
            .clipped()
        } else {
            ToolbarButtonItem(imageName: "magnifyingglass", hint: "Search", padding: 14) {
                withAnimation {
                    isInSearchMode.toggle()
                }
            }
            .frame(minWidth: 0, maxWidth: isInSearchMode ? 0 : ToolbarButtonItem.buttonWidth, minHeight: 0, maxHeight: isInSearchMode ? 0 : ToolbarButtonItem.buttonWidth)
            .clipped()
            .foregroundStyle(Color.App.toolbarButton)
        }
    }

    @ViewBuilder var leadingViews: some View {
        searchButton
        if EnvironmentValues.isTalkTest {
            ToolbarButtonItem(imageName: "list.bullet", hint: "General.select", padding: 14) {
                withAnimation {
                    viewModel.isInSelectionMode.toggle()
                }
            }
            .foregroundStyle(Color.App.toolbarButton)
            .sandboxLabel()

//            if !viewModel.showConversaitonBuilder {
//                ToolbarButtonItem(imageName: "trash.fill", hint: "General.delete", padding: 10) {
//                    withAnimation {
//                        AppState.shared.objectsContainer.appOverlayVM.dialogView = AnyView(DeleteContactView().environmentObject(viewModel))
//                    }
//                }
//                .foregroundStyle(.red)
//                .opacity(viewModel.isInSelectionMode ? 1 : 0.2)
//                .disabled(!viewModel.isInSelectionMode)
//                .scaleEffect(x: viewModel.isInSelectionMode ? 1.0 : 0.002, y: viewModel.isInSelectionMode ? 1.0 : 0.002)
//            }
        }
    }
}

struct ContactListToolbar_Previews: PreviewProvider {
    static var previews: some View {
        ContactListToolbar()
    }
}
