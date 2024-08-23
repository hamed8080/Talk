//
//  SMT+.swift
//  TalkExtensions
//
//  Created by hamed on 2/4/23.
//

import Chat

public extension SMT {
    typealias EventResult = (title: String, image: String)?

    var titleAndIcon: EventResult {
        guard let stringEvent, let eventImage else { return nil }
        return (stringEvent, eventImage)
    }

    var stringEvent: String? {
        switch self {
        case .isTyping:
            return "SMT.isTyping"
        case .recordVoice:
            return "SMT.recordVoice"
        case .uploadPicture:
            return "SMT.uploadPicture"
        case .uploadVideo:
            return "SMT.uploadVideo"
        case .uploadSound:
            return "SMT.uploadSound"
        case .uploadFile:
            return "SMT.uploadFile"
        case .unknown, .serverTime:
            return nil
        }
    }

    var eventImage: String? {
        switch self {
        case .isTyping:
            return "highlighter"
        case .recordVoice:
            return "waveform"
        case .uploadPicture:
            return "text.below.photo"
        case .uploadVideo:
            return "video.and.waveform"
        case .uploadSound:
            return "music.note"
        case .uploadFile:
            return "doc"
        case .unknown, .serverTime:
            return nil
        }
    }
}
