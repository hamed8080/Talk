//
//  SizeClassObserver.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 6/27/25.
//

import Foundation
import UIKit

@MainActor
public final class SizeClassObserver: ObservableObject {
    @Published public var horizontalSizeClass: UIUserInterfaceSizeClass = .unspecified

    private var windowSceneObserver: NSObjectProtocol?

    public init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(traitCollectionDidChange),
            name: UIScreen.didConnectNotification,
            object: nil
        )

        // Initial value setup
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            horizontalSizeClass = scene.windows.first?.traitCollection.horizontalSizeClass ?? .unspecified
        }
    }

    @objc private func traitCollectionDidChange() {
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            let newClass = scene.windows.first?.traitCollection.horizontalSizeClass ?? .unspecified
            if newClass != horizontalSizeClass {
                horizontalSizeClass = newClass
            }
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

