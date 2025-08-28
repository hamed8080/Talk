//
//  SendContainerViewModel.swift
//  TalkViewModels
//
//  Created by hamed on 10/22/22.
//

import Foundation
import Chat
import UIKit

/// LRU Cache: Stores up to 50 avatars in memory and releases the least recently used one.
@AppBackgroundActor
public class ThreadAvatarManager {
    @MainActor
    private var avatarsViewModelsQueue: [ImageLoaderViewModel] = []
    private var cachedAvatars: [String: UIImage] = [:]
    @MainActor
    private weak var viewModel: ThreadViewModel?
    private let maxCache = 50

    @MainActor
    public init() {}

    @MainActor
    public func setup(viewModel: ThreadViewModel) {
        self.viewModel = viewModel
    }

    public func addToQueue(_ viewModel: MessageRowViewModel) async {
        let message = await viewModel.message
        guard let link = httpsImage(message.participant), let participantId = message.participant?.id else { return }
        
        if Task.isCancelled {
#if DEBUG
            print("Avatar was canceled nothign will be updated")
#endif
            return
        }
        
        if let image = cachedAvatars[link] {
            updateRow(image, participantId)
        } else {
            fetchImage(for: viewModel, url: link, participantId: participantId)
        }
    }

    public func getImage(_ viewModel: MessageRowViewModel) async -> UIImage? {
        guard let link = await httpsImage(viewModel.message.participant) else { return nil }
        return cachedAvatars[link]
    }

    private func updateRow(_ image: UIImage, _ participantId: Int) {
        Task {
            await viewModel?.delegate?.updateAvatar(image: image, participantId: participantId)
        }
    }

    private func fetchImage(for viewModel: MessageRowViewModel, url: String, participantId: Int) {
        Task { @MainActor in
            guard await self.viewModel?.thread.group == true, !viewModel.calMessage.isMe, !isInQueue(url) else { return }
            await removeOldestEntry()
        
            let vm = ImageLoaderViewModel(config: ImageLoaderConfig(url: url))
            avatarsViewModelsQueue.append(vm)

            vm.onImage = { [weak self, weak vm] image in
                Task {
                    await self?.onOnImage(url: url, image: image, participantId: participantId)
                    if let vm = vm {
                        await self?.removeViewModel(vm)
                    }
                }
            }
            vm.fetch()
        }
    }
    
    private func onOnImage(url: String, image: UIImage, participantId: Int) async {
        cachedAvatars[url] = image
        await updateRow(image, participantId)
    }
    
    @MainActor
    private func isInQueue(_ url: String) -> Bool {
        avatarsViewModelsQueue.contains(where: { $0.config.url == url })
    }

    @MainActor
    private func removeViewModel(_ viewModel: ImageLoaderViewModel) {
        viewModel.clear()
        avatarsViewModelsQueue.removeAll(where: {$0.config.url == viewModel.config.url})
    }

    private func removeOldestEntry() {
        if cachedAvatars.count > maxCache, let firstKey = cachedAvatars.first?.key {
            cachedAvatars.removeValue(forKey: firstKey)
        }
    }
    
    private func httpsImage(_ participant: Participant?) -> String? {
        participant?.image?.replacingOccurrences(of: "http://", with: "https://")
    }
}
