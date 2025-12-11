//
//  TabViewButtonsContainer.swift
//  TalkUI
//
//  Created by Hamed Hosseini on 10/16/21.
//

import SwiftUI

public struct TabViewButtonsContainer: View {
    @Binding var selectedTabIndex: Int
    let tabs: [Tab]
    @Namespace var id
    @State private var width: CGFloat = 0
    @Environment(\.horizontalSizeClass) var sizeClass
    private let firstTabOnAppear: String?
    @State private var movedToFirstTabOnAppear = false

    public init(selectedTabIndex: Binding<Int>, tabs: [Tab]) {
        self._selectedTabIndex = selectedTabIndex
        self.firstTabOnAppear = tabs.first?.id
        self.tabs = tabs
    }

    public var body: some View {
        ScrollViewReader { reader in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    HStack(spacing: 28) {
                        ForEach(tabs) { tab in
                            tabButton(for: tab)
                        }
                    }
                    .animation(.spring(), value: selectedTabIndex)
                    .padding([.leading, .trailing])
                    Spacer()
                }
                .frame(width: sizeClass == .regular ? width : nil)
            }
            .background(frameReader)
            .onChange(of: firstTabOnAppear) { newValue in
                focusOnFirstTab(reader)
            }.onAppear {
                focusOnFirstTab(reader)
            }
        }
    }
    
    private func focusOnFirstTab(_ reader: ScrollViewProxy) {
        if let firstTabOnAppear = firstTabOnAppear, !movedToFirstTabOnAppear {
            movedToFirstTabOnAppear = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                reader.scrollTo(firstTabOnAppear, anchor: .leading)
            }
        }
    }

    private var frameReader: some View {
        GeometryReader { reader in
            Color.clear.onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    width = reader.size.width
                }
            }
        }
    }

    @ViewBuilder
    private func tabButton(for tab: Tab) -> some View {
        let index = tabs.firstIndex(where: { $0.title == tab.title })
        Button {
            selectedTabIndex = index ?? 0
        } label: {
            VStack(spacing: 6) {
                HStack(spacing: 8) {
                    iconView(tab: tab)
                    titleView(tab: tab, index: index)
                }
                .padding(EdgeInsets(top: 0, leading: 8, bottom: 0, trailing: 8))

                selectedTabBar(index: index)
            }
            .frame(height: 48)
            .contentShape(Rectangle())
            .fixedSize(horizontal: true, vertical: true)
        }
        .id(tab.id)
        .buttonStyle(.plain)
        .frame(height: 48)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private func selectedTabBar(index: Int?) -> some View {
        if index == selectedTabIndex {
            Rectangle()
                .fill(Color.App.accent)
                .frame(height: 3)
                .cornerRadius(2, corners: [.topLeft, .topRight])
                .matchedGeometryEffect(id: "DetailTabSeparator", in: id)
        }
    }

    private func titleView(tab: Tab, index: Int?) -> some View {
        Text(tab.title)
            .font(index == selectedTabIndex ? Font.bold(.caption) : Font.normal(.caption))
            .fixedSize()
            .foregroundStyle(index == selectedTabIndex ? Color.App.textPrimary : Color.App.textSecondary)
    }

    @ViewBuilder
    private func iconView(tab: Tab) -> some View {
        if let icon = tab.icon {
            Image(systemName: icon)
                .frame(width: 24, height: 24)
                .foregroundColor(Color.App.textSecondary)
                .fixedSize()
        }
    }
}

struct TabViewButtonsContainer_Previews: PreviewProvider {
    static var previews: some View {
        TabViewButtonsContainer(selectedTabIndex: .constant(0), tabs: [])
    }
}
