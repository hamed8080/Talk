//
//  OpenURLViewModifier.swift
//  TalkUI
//
//  Created by Hamed Hosseini on 10/16/21.
//

import Foundation
import SwiftUI
import SafariServices
import TalkViewModels

public struct OpenURLViewModifier: ViewModifier {
    @EnvironmentObject var appstate: AppState
    
    public func body(content: Content) -> some View {
        content
            .onChange(of: appstate.appStateNavigationModel.openURL) { url in
                if let url = url  {
                    let vc = SFSafariViewController(url: url)
                    vc.preferredControlTintColor = UIColor(named: "accent")
                    UIApplication.shared.firstKeyWindow?.rootViewController?.present(vc, animated: true)
                }
            }
    }
}
extension UIApplication {
    var firstKeyWindow: UIWindow? {
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .filter { $0.activationState == .foregroundActive }
            .first?.keyWindow
    }
}

public extension View {
    func addURLViewModifier() -> some View {
        modifier(OpenURLViewModifier())
    }
}
