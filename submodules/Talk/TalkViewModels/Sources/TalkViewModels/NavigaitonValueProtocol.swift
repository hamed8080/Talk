//
//  PreferenceNavigationValue.swift
//
//
//  Created by hamed on 11/15/23.
//

import Foundation
import Chat

@MainActor
public protocol NavigationTitleProtocol {
    var navigationTitle: String { get }
}

@MainActor
public protocol ConversationNavigationProtocol: NavigationTitleProtocol {
    var viewModel: ThreadViewModel? { get set }
    var threadId: Int? { get }
}

@MainActor
public protocol ConversationDetailNavigationProtocol: NavigationTitleProtocol {
    var viewModel: ThreadViewModel? { get set }
    var threadId: Int? { get }
}

public extension ConversationNavigationProtocol {
    var threadId: Int? { viewModel?.id }
    
    var navigationTitle: String { viewModel?.thread.computedTitle ?? "" }
}
