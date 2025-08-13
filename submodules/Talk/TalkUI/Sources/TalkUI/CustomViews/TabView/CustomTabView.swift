//
//  CustomTabView.swift
//  TalkUI
//
//  Created by Hamed Hosseini on 10/16/21.
//

import SwiftUI

public struct CustomTabView: View {
    @Binding var selectedTabIndex: Int
    let tabs: [Tab]

    public init(selectedTabIndex: Binding<Int> = .constant(0), tabs: [Tab]) {
        self._selectedTabIndex = selectedTabIndex
        self.tabs = tabs
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            TabViewButtonsContainer(selectedTabIndex: $selectedTabIndex, tabs: tabs)
            if tabs.indices.contains(selectedTabIndex) {
                tabs[selectedTabIndex].view
                    .transition(.asymmetric(insertion: .push(from: .leading), removal: .move(edge: .trailing)))
            }
        }
    }
}

public struct CustomDetailTabView<T: View>: View {
    @Environment(\.selectedTabIndex) var tabIndex
    let tabs: [Tab]
    let tabButtons: () -> T

    public init(tabs: [Tab], @ViewBuilder tabButtons: @escaping () -> T) {
        self.tabs = tabs
        self.tabButtons = tabButtons
    }

    public var body: some View {
        LazyVStack(alignment: .leading, spacing: 0, pinnedViews: [.sectionHeaders]) {
            Section {
                if tabs.indices.contains(tabIndex) {
                    tabs[tabIndex].view
                        .transition(.asymmetric(insertion: .push(from: .leading), removal: .move(edge: .trailing)))
                }
            } header: {
                tabButtons()
                    .background(Color.App.bgPrimary)
            }
        }
    }
}

public struct SelectedTabIndexKey: @preconcurrency EnvironmentKey {
    @MainActor
    public static var defaultValue: Int = 0
}

public extension EnvironmentValues {
    var selectedTabIndex: Int {
        get { self[SelectedTabIndexKey.self] }
        set { self[SelectedTabIndexKey.self] = newValue }
    }
}

public extension View {
    func selectedTabIndx(index: Int) -> some View {
        environment(\.selectedTabIndex, index)
    }
}

struct CustomTabView_Previews: PreviewProvider {
    static var previews: some View {
        CustomTabView(tabs: [])
    }
}
