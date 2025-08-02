//
//  MessageType+.swift
//  TalkExtensions
//
//  Created by hamed on 4/15/22.
//

import Foundation
import Chat

public extension ChatModels.MessageType {
    var iconName: String? {
        switch self {
        case .text:
            return "doc.fill"
        case .voice, .sound, .video, .podSpaceVoice, .podSpaceSound, .podSpaceVideo:
            return "play.fill"
        case .picture, .podSpacePicture:
            return "photo.fill"
        case .file, .podSpaceFile:
            return nil
        case .link:
            return "link.fill"
        case .endCall:
            return "phone.arrow.down.left"
        case .startCall:
            return "phone.arrow.up.right"
        case .sticker:
            return "face.smiling"
        case .location:
            return "map.fill"
        case .participantJoin:
            return "person.crop.rectangle.badge.plus"
        case .participantLeft:
            return "door.right.hand.open"
        case .unknown:
            return nil
        }
    }

    var fileStringName: String? {
        switch self {
        case .text:
            return "MessageType.text"
        case .voice:
            return "MessageType.voice"
        case .picture:
            return "MessageType.picture"
        case .video:
            return "MessageType.video"
        case .sound:
            return "MessageType.sound"
        case .file, .podSpaceFile:
            return "MessageType.file"
        case .podSpacePicture:
            return "MessageType.picture"
        case .podSpaceVideo:
            return "MessageType.video"
        case .podSpaceSound:
            return "MessageType.sound"
        case .podSpaceVoice:
            return "MessageType.voice"
        case .link:
            return "MessageType.link"
        case .endCall:
            return "MessageType.endCall"
        case .startCall:
            return "MessageType.startCall"
        case .sticker:
            return "MessageType.sticker"
        case .location:
            return "MessageType.location"
        case .participantJoin:
            return "MessageType.join"
        case .participantLeft:
            return "MessageType.left"
        case .unknown:
            return nil
        }
    }
}
