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
                Text("General.cancel")
                    .padding(.leading)
                    .font(.iransansBody)
                    .foregroundStyle(Color.App.primary)
            }
            .buttonStyle(.borderless)
            .frame(minWidth: 0, minHeight: 0, maxHeight: isInSearchMode ? 38 : 0)
            .clipped()
        } else {
            ToolbarButtonItem(imageName: "magnifyingglass", hint: "Search") {
                withAnimation {
                    isInSearchMode.toggle()
                }
            }
            .frame(minWidth: 0, maxWidth: isInSearchMode ? 0 : ToolbarButtonItem.buttonWidth, minHeight: 0, maxHeight: isInSearchMode ? 0 : 38)
            .clipped()
            .foregroundStyle(Color.App.primary)
            .onReceive(NotificationCenter.default.publisher(for: .cancelSearch)) { newValue in
                if let cancelSearch = newValue.object as? Bool, cancelSearch == true, cancelSearch && isInSearchMode {
                    isInSearchMode.toggle()
                }
            }
        }
    }

    @ViewBuilder var leadingViews: some View {
        searchButton
        if EnvironmentValues.isTalkTest {
            ToolbarButtonItem(imageName: "list.bullet", hint: "General.select") {
                withAnimation {
                    viewModel.isInSelectionMode.toggle()
                }
            }

            if !viewModel.showConversaitonBuilder {
                ToolbarButtonItem(imageName: "trash.fill", hint: "General.delete") {
                    withAnimation {
                        AppState.shared.objectsContainer.appOverlayVM.dialogView = AnyView(DeleteContactView().environmentObject(viewModel))
                    }
                }
                .foregroundStyle(.red)
                .opacity(viewModel.isInSelectionMode ? 1 : 0.2)
                .disabled(!viewModel.isInSelectionMode)
                .scaleEffect(x: viewModel.isInSelectionMode ? 1.0 : 0.002, y: viewModel.isInSelectionMode ? 1.0 : 0.002)
            }
        }
    }
}

struct ContactListToolbar_Previews: PreviewProvider {
    static var previews: some View {
        ContactListToolbar()
    }
}
