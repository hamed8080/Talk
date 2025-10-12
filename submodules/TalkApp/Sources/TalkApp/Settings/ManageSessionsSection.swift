//
//  ManageSessionsSection.swift
//  Talk
//
//  Created by Hamed Hosseini on 12/15/24.
//

import SwiftUI
import TalkUI
import TalkViewModels

struct ManageSessionsSection: View {
    @EnvironmentObject var navModel: NavigationModel

    var body: some View {
        ListSectionButton(imageName: "ipad.landscape", title: "Settings.ManageSessions.title", color: .blue, showDivider: false) {
            navModel.wrapAndPush(view: ManageSessionsView())
        }
        .listRowInsets(.zero)
        .listRowBackground(Color.App.bgPrimary)
        .listRowSeparatorTint(Color.App.dividerPrimary)
    }
}

#Preview {
    ManageSessionsSection()
}
