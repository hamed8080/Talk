//
//  ImageLoaderView.swift
//  TalkUI
//
//  Created by hamed on 1/18/23.
//

import Chat
import Foundation
import SwiftUI
import TalkModels
import TalkViewModels
import ChatDTO
import Combine

public struct ImageLoaderView: View {
    @StateObject var imageLoader: ImageLoaderViewModel
    let contentMode: ContentMode
    let textFont: Font

    public init(imageLoader: ImageLoaderViewModel,
                contentMode: ContentMode = .fill,
                textFont: Font = .iransansBody
    ) {
        self.textFont = textFont
        self.contentMode = contentMode
        self._imageLoader = StateObject(wrappedValue: imageLoader)
    }
    
    public init(participant: Participant?) {
        let httpsImage = participant?.image?.replacingOccurrences(of: "http://", with: "https://")
        let userName = String.splitedCharacter(participant?.name ?? participant?.username ?? "")
        let config = ImageLoaderConfig(url: httpsImage ?? "", userName: userName)
        self.init(imageLoader: .init(config: config))
    }
    
    public init(contact: Contact?, font: Font = .iransansBody) {
        let image = contact?.image ?? contact?.user?.image ?? ""
        let httpsImage = image.replacingOccurrences(of: "http://", with: "https://")
        let contactName = "\(contact?.firstName ?? "") \(contact?.lastName ?? "")"
        let isEmptyContactString = contactName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let name = !isEmptyContactString ? contactName : contact?.user?.name
        let config = ImageLoaderConfig(url: httpsImage, userName: String.splitedCharacter(name ?? ""))
        self.init(imageLoader: .init(config: config), textFont: font)
    }
    
    public init(blocked: BlockedContactResponse) {
        let image = blocked.profileImage ?? blocked.contact?.image ?? ""
        let contactName = blocked.contact?.user?.name ?? blocked.contact?.firstName
        let name = contactName ?? blocked.nickName
        let config = ImageLoaderConfig(url: image, userName: String.splitedCharacter(name ?? ""))
        self.init(imageLoader: .init(config: config))
    }
    
    public init(conversation: Conversation) {
        let image = conversation.computedImageURL ?? ""
        let httpsImage = image.replacingOccurrences(of: "http://", with: "https://")
        let userName = String.splitedCharacter(conversation.computedTitle)
        let config = ImageLoaderConfig(url: httpsImage, metaData: conversation.metadata, userName: userName)
        self.init(imageLoader: .init(config: config))
    }
    
    public init(user: User?) {
        let image = user?.image ?? ""
        let httpsImage = image.replacingOccurrences(of: "http://", with: "https://")
        let userName = String.splitedCharacter(user?.name ?? "")
        let config = ImageLoaderConfig(url: httpsImage, userName: userName)
        self.init(imageLoader: .init(config: config))
    }

    public var body: some View {
        ZStack {
            if !imageLoader.isImageReady {
                Text(String(imageLoader.config.userName ?? " "))
                    .font(textFont)
            } else if imageLoader.isImageReady {
                Image(uiImage: imageLoader.image)
                    .interpolation(.none)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            }
        }
        .animation(.easeInOut, value: imageLoader.image)
        .animation(.easeInOut, value: imageLoader.isImageReady)
        .onAppear {
            if !imageLoader.isImageReady {
                imageLoader.fetch()
            }
        }
    }
}
