//
//  AppSettingsModel.swift
//  TalkViewModels
//
//  Created by hamed on 10/22/22.
//
import Foundation
import Combine
import Chat

@MainActor
public struct AppSettingsModel: Codable, Hashable, Sendable {
    nonisolated public static func == (lhs: AppSettingsModel, rhs: AppSettingsModel) -> Bool {
        lhs.hashValue == rhs.hashValue
    }

    nonisolated public func hash(into hasher: inout Hasher) {
        hasher.combine(isSyncOn)
        hasher.combine(notificationSettings.data)
        hasher.combine(automaticDownloadSettings.data)
    }

    static let key = "AppSettingsKey"
    public var isSyncOn: Bool = false
    public var isAutoPlayVideoEnabled = true
    public var isDarkModeEnabled: Bool? = nil
    
    /// Default value is true
    public var isSaveScrollPosition: Bool? = true
    public var notificationSettings: NotificationSettingModel = .init()
    public var automaticDownloadSettings: AutomaticDownloadSettingModel = .init()
    @MainActor
    public enum DoubleTapAction: Codable {
        case reply
        case specialEmoji(Sticker)
    }
    public var doubleTapAction: DoubleTapAction? = .reply
    
    public func save() {
        UserDefaults.standard.setValue(codable: self, forKey: AppSettingsModel.key)
        NotificationCenter.appSettingsModel.post(name: .appSettingsModel, object: self)
    }

    public static func restore() -> AppSettingsModel {
        let value: AppSettingsModel? = UserDefaults.standard.codableValue(forKey: AppSettingsModel.key)
        return value ?? .init()
    }
}

/// Automatic download settings.
public struct AutomaticDownloadSettingModel: Codable, Sendable {
    public var downloadImages: Bool = false
    public var downloadFiles: Bool = false
    public var privateChat: ChatSettings = .init()
    public var channel: ChannelSettings = .init()
    public var group: GroupSettings = .init()

    public struct ChatSettings: Codable, Sendable {
        public var downloadImages: Bool = false
        public var downloadFiles: Bool = false
    }

    public struct ChannelSettings: Codable, Sendable {
        public var downloadImages: Bool = false
        public var downloadFiles: Bool = false
    }

    public struct GroupSettings: Codable, Sendable {
        public var downloadImages: Bool = false
        public var downloadFiles: Bool = false
    }

    public func reset() {

    }
}

public struct NotificationSettingModel: Codable, Sendable {
    public var soundEnable: Bool = true
    public var showDetails: Bool = true
    public var vibration: Bool = true
    public var privateChat: ChatSettings = .init()
    public var channel: ChannelSettings = .init()
    public var group: GroupSettings = .init()

    public struct ChatSettings: Codable, Sendable {
        public var showNotification: Bool = true
        public var sound = true
    }

    public struct ChannelSettings: Codable, Sendable {
        public  var showNotification: Bool = true
        public  var sound = true
    }

    public struct GroupSettings: Codable, Sendable {
        public var showNotification: Bool = true
        public var sound = true
    }

    public func reset() {

    }
}
