//
//  SendContainerViewModel.swift
//  TalkViewModels
//
//  Created by hamed on 10/22/22.
//

import Foundation
import ChatModels
import UIKit

@AppBackgroundActor
public class ThreadAvatarManager {
    @MainActor
    private var avatarsViewModelsQueue: [ImageLoaderViewModel] = []
    private var cachedAvatars: [String: UIImage] = [:]
    private weak var viewModel: ThreadViewModel?
    private let maxCache = 50

    @MainActor
    public init() {}

    @MainActor
    public func setup(viewModel: ThreadViewModel) {
        Task { @AppBackgroundActor in
            self.viewModel = viewModel
        }
    }

    public func addToQueue(_ viewModel: MessageRowViewModel) {
        addOrUpdate(viewModel)
    }

    private func addOrUpdate(_ viewModel: MessageRowViewModel) {
        let participant = viewModel.message.participant
        guard let link = httpsImage(participant),
              let participantId = participant?.id
        else { return }
        if let image = cachedAvatars[link] {
            updateRow(image, participantId)
        } else {
            create(viewModel)
        }
    }

    public func getImage(_ viewModel: MessageRowViewModel) -> UIImage? {
        let participant = viewModel.message.participant
        guard let link = httpsImage(participant) else { return nil }
        return cachedAvatars[link]
    }

    private func updateRow(_ image: UIImage, _ participantId: Int) {
        Task {
            let delegate = await viewModel?.delegate
            await MainActor.run { [weak self] in
                delegate?.updateAvatar(image: image, participantId: participantId)
            }
        }
    }

    private func create(_ viewModel: MessageRowViewModel) {
        Task { @MainActor in
            guard await self.viewModel?.thread.group == true, !viewModel.calMessage.isMe, let url = await httpsImage(viewModel.message.participant) else { return }
            if await isInQueue(url) { return }
            await releaseFromBottom()
            let config = ImageLoaderConfig(url: url)
            let vm = ImageLoaderViewModel(config: config)
            avatarsViewModelsQueue.append(vm)
            let participantId = viewModel.message.participant?.id ?? -1
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

    private func releaseFromBottom() {
        if cachedAvatars.count > maxCache, let firstKey = cachedAvatars.first?.key {
            cachedAvatars.removeValue(forKey: firstKey)
        }
    }
    
    private func httpsImage(_ participant: Participant?) -> String? {
        participant?.image?.replacingOccurrences(of: "http://", with: "https://")
    }
}
