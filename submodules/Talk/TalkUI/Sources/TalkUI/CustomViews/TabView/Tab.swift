//
//  Tab.swift
//  TalkUI
//
//  Created by Hamed Hosseini on 10/16/21.
//

import Foundation
import SwiftUI

public struct Tab: Identifiable {
    public var id: String { title }
    public let title: String
    public let icon: String?
    public var view: AnyView?

    public init(title: String, icon: String? = nil, view: AnyView? = nil) {
        self.title = title
        self.icon = icon
        self.view = view
    }
}
