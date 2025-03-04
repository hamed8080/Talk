//
//  ThreadListSearchBarFilterView.swift
//  Talk
//
//  Created by hamed on 12/13/23.
//

import SwiftUI
import TalkViewModels
import TalkModels
import ActionableContextMenu
import TalkUI

struct ThreadListSearchBarFilterView: View {
    @State private var showPopover = false
    @Binding var isInSearchMode: Bool
    @EnvironmentObject var viewModel: ThreadsSearchViewModel
    enum Field: Hashable {
        case saerch
    }
    @FocusState var searchFocus: Field?

    var body: some View {
        VStack {
            if isInSearchMode {
                HStack {
                    searchField
                    filterButton
                }
                .transition(.asymmetric(insertion: .push(from: .top), removal: .push(from: .bottom)))
            }
            selectedSearchFilters
        }
        .animation(.easeInOut, value: isInSearchMode)
        .animation(.easeInOut, value: viewModel.showUnreadConversations)
        .padding(EdgeInsets(top: isInSearchMode ? 4 : 0, leading: 4, bottom: isInSearchMode ? 6 : 0, trailing: 4))
        .onChange(of: viewModel.searchText) { newValue in
            AppState.shared.objectsContainer.contactsVM.searchContactString = newValue
            viewModel.searchText = newValue
        }
        .onReceive(NotificationCenter.forceSearch.publisher(for: .forceSearch)) { newValue in
            if newValue.object as? String == "Tab.chats" {
                Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
                    Task { @MainActor in
                        isInSearchMode.toggle()
                        searchFocus = .saerch
                    }
                }
            }
        }
    }

    private var searchField: some View {
        TextField("General.searchHere".bundleLocalized(), text: $viewModel.searchText)
            .font(.fBody)
            .textFieldStyle(.clear)
            .submitLabel(.done)
            .focused($searchFocus, equals: .saerch)
            .frame(minWidth: 0, maxWidth: nil, minHeight: 0, maxHeight: 38)
            .clipped()
            .transition(.asymmetric(insertion: .push(from: .top), removal: .move(edge: .top).combined(with: .opacity)))
            .foregroundStyle(viewModel.searchText.count == 0 ? Color.App.textPrimary.opacity(0.7) : Color.App.textPrimary)
            .background {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.clear)
                    .background(Color.App.bgSendInput.opacity(0.8))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .onAppear {
                if isInSearchMode && searchFocus != .saerch {
                    searchFocus = .saerch
                }
            }
    }

    private var filterButton: some View {
        Button {
            AppState.shared.objectsContainer.appOverlayVM.dialogView = AnyView(
                SearchFiltersMessagesDialog()
                    .environmentObject(viewModel)
            )
        } label: {
            Image("ic_search_filter")
                .resizable()
                .scaledToFit()
                .frame(width: 22, height: 22)
                .fontWeight(.medium)
                .foregroundColor(Color.App.textSecondary)
        }
    }

    @ViewBuilder
    private var selectedSearchFilters: some View {
        if viewModel.showUnreadConversations == true {
            HStack {
                FilterChip(text: "Filters.onlyUnreadConversations") {
                    /// On remove
                    viewModel.showUnreadConversations?.toggle()
                }
                Spacer()
            }
        }
    }

    //    private var threadTypeButton: some View {
    //                Button {
    //                    showPopover.toggle()
    //                } label: {
    //                    HStack {
    //                        Text(String(localized: .init(viewModel.searchType.rawValue)))
    //                            .font(.fBoldCaption3)
    //                            .foregroundColor(Color.App.textSecondary)
    //                        Image(systemName: "chevron.down")
    //                            .resizable()
    //                            .scaledToFit()
    //                            .frame(width: 8, height: 12)
    //                            .fontWeight(.medium)
    //                            .foregroundColor(Color.App.textSecondary)
    //                    }
    //                }
    //                .popover(isPresented: $showPopover, attachmentAnchor: .point(.bottom), arrowEdge: .bottom) {
    //                    VStack(alignment: .leading, spacing: 0) {
    //                        ForEach(SearchParticipantType.allCases.filter({ $0 != .admin })) { item in
    //                            ContextMenuButton(title: String(localized: .init(item.rawValue)), image: "") {
    //                                withAnimation {
    //                                    showPopover.toggle()
    //                                    viewModel.searchType = item
    //                                }
    //                            }
    //                        }
    //                    }
    //                    .foregroundColor(.primary)
    //                    .frame(width: 196)
    //                    .background(MixMaterialBackground())
    //                    .clipShape(RoundedRectangle(cornerRadius:((12))))
    //                    .presentationCompactAdaptation(horizontal: .popover, vertical: .popover)
    //                }
    //    }
}

struct FilterChip: View {
    let text: String
    let action: () -> Void
    @State var isSelectedToDelete: Bool = false

    var body: some View {
        HStack {
            Image(systemName: "xmark")
                .resizable()
                .scaledToFit()
                .frame(width: 14, height: 14)
                .foregroundStyle(Color.App.white)
                .contentShape(Rectangle())
            Text(String(localized: .init(text)))
                .lineLimit(1)
                .font(.fCaption2)
                .foregroundColor(isSelectedToDelete ? Color.App.white : Color.App.textPrimary)
        }
        .padding(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
        .background(isSelectedToDelete ?  Color.App.accent : Color.App.textSecondary)
        .clipShape(RoundedRectangle(cornerRadius:(12)))
        .animation(.easeInOut, value: isSelectedToDelete)
        .transition(.scale)
        .onTapGesture {
            action()            
        }
    }
}

struct ThreadListSearchBarFilterView_Previews: PreviewProvider {
    static var previews: some View {
        ThreadListSearchBarFilterView(isInSearchMode: .constant(true))
    }
}
