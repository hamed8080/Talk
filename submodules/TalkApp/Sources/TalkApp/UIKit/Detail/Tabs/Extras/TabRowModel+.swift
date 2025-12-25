//
//  TabRowModel+.swift
//  TalkApp
//
//  Created by Hamed Hosseini on 12/25/25.
//

import TalkUI
import SwiftUI

public extension TabRowModel {
    func presentShareSheet(parentVC: UIViewController?) async {
        let tempURL = await self.makeTempURL()
        let view = ActivityViewControllerWrapper(activityItems: [tempURL], title: self.metadata?.file?.originalName)
            .background(Color.clear)
        let vc = UIHostingController(rootView: view)
        vc.modalPresentationStyle = .formSheet
        vc.overrideUserInterfaceStyle = AppSettingsModel.restore().isDarkModeEnabled ?? false ? .dark : .light
        parentVC?.present(vc, animated: true)
    }
}
