//
//  Color+.swift
//  TalkUI
//
//  Created by Hamed Hosseini on 11/30/21.
//

import Foundation
import SwiftUI

public extension Color {
    init(named: String) {
        self = Color(UIColor(named: named)!)
    }

    static var random: Color {
        Color(uiColor: UIColor.random())
    }

    struct App {
        public static let textPrimary = Color("text_primary")
        public static let textSecondary = Color("text_secondary")
        public static let textPlaceholder = Color("text_placeholder")
        public static let iconPrimary = Color("iconPrimary")
        public static let iconSecondary = Color("icon_secondary")
        public static let bgLargeButton = Color("bg_large_button")
        public static let bgPrimary = Color("bg_primary")
        public static let bgSecondary = Color("bg_secondary")
        public static let bgIcon = Color("bg_icon")
        public static let bgSpacer = Color("bg_spacer")
        public static let bgBadgeMute = Color("bg_badge_mute")
        public static let bgBadgeUnMute = Color("bg_badge_unMute")
        public static let bgChatMe = Color("bg_chat_me")
        public static let bgChatMeDark = Color("bg_chat_me_dark")
        public static let bgChatUser = Color("bg_chat_user")
        public static let bgChatUserDark = Color("bg_chat_user_dark")
        public static let bgChatSelected = Color("bg_chat_selected")
        public static let bgChatCheck = Color("bg_chat_check")
        public static let bgChat = Color("bg_chat")
        public static let bgInputChatbox = Color("bg_input_chatbox")
        public static let bgSendInput = Color("bg_send_input")
        public static let bgInput = Color("bg_input")
        public static let bgOffline = Color("bg_offline")
        public static let bgOnline = Color("bg_online")
        public static let bgScrollbar = Color("bg_scrollbar")
        public static let dividerPrimary = Color("divider_primary")
        public static let dividerSecondary = Color("divider_secondary")
        public static let toolbarButton = Color("toolbar_button")
        public static let toolbarSecondaryText = Color("toolbar_secondary_text")
        public static let bgToolbar = Color("bg_toolbar")
        public static let accent = Color("accent")
        public static let white = Color("white")
        public static let color1 = Color("color1")
        public static let color2 = Color("color2")
        public static let color3 = Color("color3")
        public static let color4 = Color("color4")
        public static let color5 = Color("color5")
        public static let color6 = Color("color6")
        public static let color7 = Color("color7")

        /// Custom color
        public static let red = Color("red")
        public static let redUIColor = UIColor(named: "red")

        public static let textPrimaryUIColor = UIColor(named: "text_primary")
        public static let textSecondaryUIColor = UIColor(named: "text_secondary")
        public static let textPlaceholderUIColor = UIColor(named: "text_placeholder")
        public static let iconPrimaryUIColor = UIColor(named: "iconPrimary")
        public static let iconSecondaryUIColor = UIColor(named: "icon_secondary")
        public static let bgLargeButtonUIColor = UIColor(named: "bg_large_button")
        public static let bgPrimaryUIColor = UIColor(named: "bg_primary")
        public static let bgSecondaryUIColor = UIColor(named: "bg_secondary")
        public static let bgIconUIColor = UIColor(named: "bg_icon")
        public static let bgSpacerUIColor = UIColor(named: "bg_spacer")
        public static let bgBadgeMuteUIColor = UIColor(named: "bg_badge_mute")
        public static let bgBadgeUnMuteUIColor = UIColor(named: "bg_badge_unMute")
        public static let bgChatMeUIColor = UIColor(named: "bg_chat_me")
        public static let bgChatMeDarkUIColor = UIColor(named: "bg_chat_me_dark")
        public static let bgChatUserUIColor = UIColor(named: "bg_chat_user")
        public static let bgChatUserDarkUIColor = UIColor(named: "bg_chat_user_dark")
        public static let bgChatSelectedUIColor = UIColor(named: "bg_chat_selected")
        public static let bgChatCheckUIColor = UIColor(named: "bg_chat_check")
        public static let bgChatUIColor = UIColor(named: "bg_chat")
        public static let bgInputChatboxUIColor = UIColor(named: "bg_input_chatbox")
        public static let bgSendInputUIColor = UIColor(named: "bg_send_input")
        public static let bgInputUIColor = UIColor(named: "bg_input")
        public static let bgOfflineUIColor = UIColor(named: "bg_offline")
        public static let bgOnlineUIColor = UIColor(named: "bg_online")
        public static let bgScrollbarUIColor = UIColor(named: "bg_scrollbar")
        public static let dividerPrimaryUIColor = UIColor(named: "divider_primary")
        public static let dividerSecondaryUIColor = UIColor(named: "divider_secondary")
        public static let toolbarButtonUIColor = UIColor(named: "toolbar_button")
        public static let toolbarSecondaryTextUIColor = UIColor(named: "toolbar_secondary_text")
        public static let bgToolbarUIColor = UIColor(named: "bg_toolbar")
        public static let accentUIColor = UIColor(named: "accent")
        public static let whiteUIColor = UIColor(named: "white")
        public static let color1UIColor = UIColor(named: "color1")
        public static let color2UIColor = UIColor(named: "color2")
        public static let color3UIColor = UIColor(named: "color3")
        public static let color4UIColor = UIColor(named: "color4")
        public static let color5UIColor = UIColor(named: "color5")
        public static let color6UIColor = UIColor(named: "color6")
        public static let color7UIColor = UIColor(named: "color7")
    }
}
