//
//  PreferenceNavigationValue.swift
//
//
//  Created by hamed on 11/15/23.
//

import Foundation
import Chat

@MainActor
public protocol NavigationTitle {
    var title: String { get }
}

@MainActor
public protocol NavigaitonValueProtocol: Hashable, NavigationTitle {
    var navType: NavigationType { get }
}

public struct PreferenceNavigationValue: NavigaitonValueProtocol {
    public let title: String = "Settings.title"
    public var navType: NavigationType { .preference(self) }
    public init() {}
}

public struct AssistantNavigationValue: NavigaitonValueProtocol {
    public var title: String = "Assistant.Assistants"
    public var navType: NavigationType { .assistant(self) }
    public init() {}
}

public struct LogNavigationValue: NavigaitonValueProtocol {
    public var title: String = "Logs.title"
    public var navType: NavigationType { .log(self) }
    public init() {}
}

public struct ArchivesNavigationValue: NavigaitonValueProtocol {
    public var title: String = "Tab.archives"
    public var navType: NavigationType { .archives(self) }
    public init() {}
}

public struct LanguageNavigationValue: NavigaitonValueProtocol {
    public var title: String = "Settings.language"
    public var navType: NavigationType { .language(self) }
    public init() {}
}

public struct BlockedContactsNavigationValue: NavigaitonValueProtocol {
    public var title: String = "Contacts.blockedList"
    public var navType: NavigationType { .blockedContacts(self) }
    public init() {}
}

public struct NotificationSettingsNavigationValue: NavigaitonValueProtocol {
    public var title: String = "Settings.notifictionSettings"
    public var navType: NavigationType { .notificationSettings(self) }
    public init() {}
}

public struct AutomaticDownloadsNavigationValue: NavigaitonValueProtocol {
    public var title: String = "Settings.download"
    public var navType: NavigationType { .automaticDownloadsSettings(self) }
    public init() {}
}

public struct SupportNavigationValue: NavigaitonValueProtocol {
    public var title: String = "Settings.about"
    public var navType: NavigationType { .support(self) }
    public init() {}
}

public struct MessageParticipantsSeenNavigationValue: NavigaitonValueProtocol {
    public var title: String = "SeenParticipants.title"
    public let message: Message
    public let threadVM: ThreadViewModel
    public let threadId: Int?
    public var navType: NavigationType { .messageParticipantsSeen(self) }
    
    nonisolated public static func ==(rhs: MessageParticipantsSeenNavigationValue, lhs: MessageParticipantsSeenNavigationValue) -> Bool {
        rhs.threadId == lhs.threadId
    }
    
    nonisolated public func hash(into hasher: inout Hasher) {
        hasher.combine(threadId)
    }

    public init(message: Message, threadVM: ThreadViewModel) {
        self.message = message
        self.threadVM = threadVM
        self.threadId = threadVM.threadId
    }
}

public struct ConversationNavigationValue: NavigaitonValueProtocol {
    public var viewModel: ThreadViewModel
    public var title: String { viewModel.thread.computedTitle }
    public var navType: NavigationType { .threadViewModel(self) }
    public let threadId: Int?
    
    nonisolated public static func ==(rhs: ConversationNavigationValue, lhs: ConversationNavigationValue) -> Bool {
        rhs.threadId == lhs.threadId
    }
    
    nonisolated public func hash(into hasher: inout Hasher) {
        hasher.combine(threadId)
    }
    
    public init(viewModel: ThreadViewModel) {
        self.viewModel = viewModel
        self.threadId = viewModel.threadId
    }
}

public struct ConversationDetailNavigationValue: NavigaitonValueProtocol {
    public var viewModel: ThreadDetailViewModel
    public let threadId: Int?
    public var title: String { "" }
    public var navType: NavigationType { .threadDetail(self) }
    
    nonisolated public static func ==(rhs: ConversationDetailNavigationValue, lhs: ConversationDetailNavigationValue) -> Bool {
        rhs.threadId == lhs.threadId
    }
    
    nonisolated public func hash(into hasher: inout Hasher) {
        hasher.combine(threadId)
    }

    public init(viewModel: ThreadDetailViewModel) {
        self.viewModel = viewModel
        self.threadId = viewModel.thread?.id
    }
}

public struct EditProfileNavigationValue: NavigaitonValueProtocol {
    public var title: String = "Settings.EditProfile.title"
    public var navType: NavigationType { .editProfile(self) }
    public init() {}
}

public struct LoadTestsNavigationValue: NavigaitonValueProtocol {
    public var title: String = "Load Tests"
    public var navType: NavigationType { .loadTests(self) }

    public init() {}
}

public struct ManageConnectionNavigationValue: NavigaitonValueProtocol {
    public var title: String = "Manage Connection"
    public var navType: NavigationType { .manageConnection(self) }

    public init() {}
}

public struct ManageSessionsNavigationValue: NavigaitonValueProtocol {
    public var title: String = "Settings.ManageSessions.title"
    public var navType: NavigationType { .manageSessions(self) }
    public init() {}
}
