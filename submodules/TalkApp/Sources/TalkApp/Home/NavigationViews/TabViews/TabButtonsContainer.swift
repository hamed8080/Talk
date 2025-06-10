//
//  TabButtonsContainer.swift
//  Talk
//
//  Created by hamed on 9/14/23.
//

import SwiftUI
import TalkUI

struct TabButtonsContainer: View {
    @Binding var selectedId: String
    let tabs: [TabItem]
    let scrollable: Bool

    var body: some View {
        if scrollable {
            scrollableContainer
        } else {
            hSatckContainer
                .frame(height: 36)
                .padding(EdgeInsets(top: 16, leading: 0, bottom: isMacOS ? 16 : 4, trailing: 0))
                .background(MixMaterialBackground().ignoresSafeArea())
        }
    }

    private var scrollableContainer: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal) {
                hSatckContainer
            }
            .frame(height: 36)
            .padding(EdgeInsets(top: 16, leading: 0, bottom: isMacOS ? 16 : 4, trailing: 0))
            .background(MixMaterialBackground().ignoresSafeArea())
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    proxy.scrollTo(selectedId)
                }
            }
        }
    }

    private var hSatckContainer: some View {
        HStack {
            ForEach(tabs) { tab in
                if !scrollable {
                    Spacer()
                }
                TabButtonItem(title: tab.title,
                              image: tab.image,
                              imageView: tab.tabImageView,
                              contextMenu: tab.contextMenus,
                              isSelected: selectedId == tab.title,
                              showSelectedDivider: tab.showSelectedDivider
                ) {
                    selectedId = tab.title
                    NotificationCenter.selectTab.post(name: .selectTab, object: tab.title)
                }
                .id(tab.id)
                if !scrollable {
                    Spacer()
                }
            }
        }
    }
    
    private var isMacOS: Bool {
        UIDevice.current.userInterfaceIdiom == .mac
    }
}

struct TabItems_Previews: PreviewProvider {
    static var previews: some View {
        TabButtonsContainer(selectedId: .constant(""), tabs: [], scrollable: false)
    }
}
