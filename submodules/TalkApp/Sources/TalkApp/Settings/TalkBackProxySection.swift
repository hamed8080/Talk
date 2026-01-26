//
//  TalkBackProxySection.swift
//  Talk
//
//  Created by Hamed Hosseini on 12/15/24.
//

import SwiftUI
import TalkUI
import TalkViewModels

struct TalkBackProxySection: View {
    @EnvironmentObject var navModel: NavigationModel

    var body: some View {
        ListSectionButton(imageName: "checkmark.shield", title: "Settings.connectionSettings", showDivider: false) {
            navModel.wrapAndPush(view: TalkBackProxyView().environmentObject(navModel).environmentObject(TalkBackProxyViewModel()))
        }
        .listRowInsets(.zero)
        .listRowBackground(Color.App.bgPrimary)
        .listRowSeparatorTint(Color.App.dividerPrimary)
    }
}

#Preview {
    TalkBackProxySection()
}
