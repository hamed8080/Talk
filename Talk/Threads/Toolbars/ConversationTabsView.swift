//
//  ConversationTabsView.swift
//  Talk
//
//  Created by hamed on 11/3/23.
//

import SwiftUI

enum ConversationsTab {
    case all
    case archive

    var title: String {
        switch self {
        case .all:
            "ConversationsTabs.all"
        case .archive:
            "ConversationsTabs.archive"
        }
    }
}

struct ConversationTabsView: View {
    @Binding var selectedTab: ConversationsTab
    @Namespace var id

    var body: some View {
        HStack(spacing: 16) {
            tabButton(tab: .all)
            tabButton(tab: .archive)
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
    }

    @ViewBuilder
    func tabButton(tab: ConversationsTab) -> some View {
        Button {
            selectedTab = tab
        } label: {
            VStack(spacing: selectedTab == tab ? 8 : 0) {
                Text(tab.title.bundleLocalized())
                    .foregroundStyle(Color.App.textPrimary)
                    .font(.iransansBoldCaption2)
                if selectedTab == tab {
                    barView
                }
            }
            .frame(minWidth: 64)
            .fixedSize(horizontal: true, vertical: true)
        }
        .buttonStyle(.plain)
    }

    private var barView: some View {
        Rectangle()
            .fill(Color.App.accent)
            .frame(height: 4)
            .transition(.move(edge: .bottom))
            .animation(.easeInOut, value: selectedTab)
            .clipShape(RoundedRectangle(cornerRadius:(4)))
            .matchedGeometryEffect(id: "barView", in: id)
    }
}

struct ConversationTabsView_Previews: PreviewProvider {
    struct Preview: View {
        @State private var selectedTab: ConversationsTab = .all

        var body: some View {
            ConversationTabsView(selectedTab: $selectedTab)
        }
    }

    static var previews: some View {
        Preview()
    }
}
