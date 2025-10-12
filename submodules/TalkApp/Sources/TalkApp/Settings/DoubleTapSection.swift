//
//  DoubleTapSection.swift
//  TalkApp
//
//  Created by Hamed Hosseini on 6/28/25.
//

import SwiftUI
import TalkUI
import TalkViewModels

struct DoubleTapSection: View {
    @EnvironmentObject var navModel: NavigationModel

    var body: some View {
        ListSectionButton(imageName: "hand.tap.fill", title: "Settings.DoubleTap.title", color: .App.color4, showDivider: false) {
            navModel.wrapAndPush(view: DoubleTapSettingView().environmentObject(navModel))
        }
        .listRowInsets(.zero)
        .listRowBackground(Color.App.bgPrimary)
        .listRowSeparatorTint(Color.App.dividerPrimary)
    }
}

#Preview {
    DoubleTapSection()
}
