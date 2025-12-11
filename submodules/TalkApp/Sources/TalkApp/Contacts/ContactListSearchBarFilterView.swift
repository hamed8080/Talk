//
//  ContactListSearchBarFilterView.swift
//  Talk
//
//  Created by hamed on 12/13/23.
//

import SwiftUI
import TalkViewModels
import TalkModels

struct ContactListSearchBarFilterView: View {
    @Binding var isInSearchMode: Bool
    @EnvironmentObject var viewModel: ContactsViewModel
    enum Field: Hashable {
        case search
    }
    @FocusState var searchFocus: Field?

    var body: some View {
        HStack {
            if isInSearchMode {
                TextField("General.searchHere".bundleLocalized(), text: $viewModel.searchContactString)
                    .font(Font.normal(.body))
                    .textFieldStyle(.clear)
                    .submitLabel(.done)
                    .focused($searchFocus, equals: .search)
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: 38)
                    .clipped()
                    .transition(.asymmetric(insertion: .push(from: .top), removal: .move(edge: .top).combined(with: .opacity)))
                    .background {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.clear)
                            .background(.thinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                Menu {
                    ForEach(SearchParticipantType.allCases.filter({ $0 != .admin })) { item in
                        Button {
                            withAnimation {
                                viewModel.searchType = item
                            }
                        } label: {
                            Text(item.rawValue)
                                .font(Font.bold(.caption))
                        }
                    }
                } label: {
                    HStack {
                        Text(viewModel.searchType.rawValue)
                            .font(Font.bold(.caption))
                            .foregroundColor(Color.App.textSecondary)
                        Image(systemName: "chevron.down")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 8, height: 12)
                            .fontWeight(.medium)
                            .foregroundColor(Color.App.textSecondary)
                    }
                }
            }
        }
        .animation(.easeInOut.speed(2), value: isInSearchMode)
        .padding(EdgeInsets(top: isInSearchMode ? 4 : 0, leading: 4, bottom: isInSearchMode ? 6 : 0, trailing: 4))        
        .onReceive(NotificationCenter.forceSearch.publisher(for: .forceSearch)) { newValue in
            if newValue.object as? String == "Tab.contacts" {
                Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
                    Task { @MainActor in
                        isInSearchMode.toggle()
                        searchFocus = .search
                    }
                }
            }
        }
    }
}

struct ContactListSearchBarFilterView_Previews: PreviewProvider {
    static var previews: some View {
        ContactListSearchBarFilterView(isInSearchMode: .constant(true))
    }
}
