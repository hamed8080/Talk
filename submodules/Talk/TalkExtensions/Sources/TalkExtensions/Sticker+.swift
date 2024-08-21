//
//  Sticker+.swift
//  Talk
//
//  Created by hamed on 8/12/23.
//

import Foundation
import Chat

public extension Sticker {
    var string: String {
        switch self {
        case .hifive:
            return "hifive"
        case .like:
            return "like"
        case .happy:
            return "happy"
        case .cry:
            return "cry"
        case .thumbsdown:
            return "Thumbs down"
        case .redHeart:
            return "Red Heart"
        case .angryFace:
            return "Angry face"
        case .verification:
            return "verification"
        case .heartEyes:
            return "Heart Eyes"
        case .clappingHands:
            return "Clapping Hands"
        case .faceScreaming:
            return "Face screaming"
        case .flushingFace:
            return "Flushing face"
        case .grimacingFace:
            return "Grimacing face"
        case .noExpressionFace:
            return "No expression face"
        case .rofl:
            return "ROFL"
        case .facepalmingGirl:
            return "Facepalming GIRL"
        case .facepalmingBoy:
            return "Facepalming BOY"
        case .swearingFace:
            return "Swearing face"
        case .blowingAKissFace:
            return "Blowing a kiss face"
        case .seeNnoEvilMonkey:
            return "See-no-evil monkey"
        case .tulip:
            return "Tulip"
        case .greenHeart:
            return "Green heart"
        case .purpleHeart:
            return "Purple Heart"
        case .bdCake:
            return "BD cake"
        case .hundredPoints:
            return "Hundred points"
        case .alarm:
            return "alarm"
        case .partyPopper:
            return "Party popper"
        case .personWalking:
            return "Person Walking"
        case .smilingPoo:
            return "Smiling poo"
        case .cryingLoudlyFace:
            return "Crying loudly face"
        case .unknown:
            return "unknown"
        }
    }

    var emoji: String {
        switch self {
        case .hifive:
            return "🙏"
        case .like:
            return "👍"
        case .happy:
            return "😄"
        case .cry:
            return "😢"
        case .thumbsdown:
            return "👎"
        case .redHeart:
            return "❤️"
        case .angryFace:
            return "😡"
        case .verification:
            return "✅"
        case .heartEyes:
            return "😍"
        case .clappingHands:
            return "👏"
        case .faceScreaming:
            return "😱"
        case .flushingFace:
            return "😳"
        case .grimacingFace:
            return "😬"
        case .noExpressionFace:
            return "😑"
        case .rofl:
            return "🤣"
        case .facepalmingGirl:
            return "🤦‍♀️"
        case .facepalmingBoy:
            return "🤦‍♂️"
        case .swearingFace:
            return "🤬"
        case .blowingAKissFace:
            return "😘"
        case .seeNnoEvilMonkey:
            return "🙈"
        case .tulip:
            return "💐"
        case .greenHeart:
            return "💚"
        case .purpleHeart:
            return "💜"
        case .bdCake:
            return "🎂"
        case .hundredPoints:
            return "💯"
        case .alarm:
            return "🚨"
        case .partyPopper:
            return "🎉"
        case .personWalking:
            return "🚶"
        case .smilingPoo:
            return "💩"
        case .cryingLoudlyFace:
            return "😭"
        case .unknown:
            return ""
        }
    }

    init?(emoji: Character) {
        switch emoji {
        case "🙏":
            self = .hifive
        case "👍":
            self = .like
        case "😄":
            self = .happy
        case "😢":
            self = .cry
        case "👎":
            self = .thumbsdown
        case "❤️":
            self = .redHeart
        case "😡":
            self = .angryFace
        case "✅":
            self = .verification
        case "😍":
            self = .heartEyes
        case "👏":
            self = .clappingHands
        case "😱":
            self = .faceScreaming
        case "😳":
            self = .flushingFace
        case "😬":
            self = .grimacingFace
        case "😑":
            self = .noExpressionFace
        case "🤣":
            self = .rofl
        case "🤦‍♀️":
            self = .facepalmingGirl
        case "🤦‍♂️":
            self = .facepalmingBoy
        case "🤬":
            self = .swearingFace
        case "😘":
            self = .blowingAKissFace
        case "🙈":
            self = .seeNnoEvilMonkey
        case "💐":
            self = .tulip
        case "💚":
            self = .greenHeart
        case "💜":
            self = .purpleHeart
        case "🎂":
            self = .bdCake
        case "💯":
            self = .hundredPoints
        case "🚨":
            self = .alarm
        case "🎉":
            self = .partyPopper
        case "🚶":
            self = .personWalking
        case "💩":
            self = .smilingPoo
        case "😭":
            self = .cryingLoudlyFace
        default:
            return nil
        }
    }
}
