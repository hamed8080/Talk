//
//  SendContainerViewModel.swift
//  TalkViewModels
//
//  Created by hamed on 10/22/22.
//

import Foundation
import UIKit

@MainActor
public class ThreadAvatarManager {
    private var queue = DispatchQueue(label: "ThreadAvatarManagerSerialQueue")
    private var avatarsViewModelsQueue: [ImageLoaderViewModel] = []
    private var cachedAvatars: [String: UIImage] = [:]
    private weak var viewModel: ThreadViewModel?
    private let maxCache = 50

    public init() {}

    public func setup(viewModel: ThreadViewModel) {
        self.viewModel = viewModel
    }

    public func addToQueue(_ viewModel: MessageRowViewModel) {
        queue.async { [weak self] in
            Task { @MainActor in
                self?.addOrUpdate(viewModel)
            }
        }
    }

    private func addOrUpdate(_ viewModel: MessageRowViewModel) {
        let participant = viewModel.message.participant
        guard let link = participant?.image,
              let participantId = participant?.id
        else { return }
        if let image = cachedAvatars[link] {
            updateRow(image, participantId)
        } else {
            create(viewModel)
        }
    }

    public func getImage(_ viewModel: MessageRowViewModel) -> UIImage? {
        queue.sync {
            let participant = viewModel.message.participant
            guard let link = participant?.image else { return nil }
            return cachedAvatars[link]
        }
    }

    public func updateRow(_ image: UIImage, _ participantId: Int) {
        DispatchQueue.main.async { [weak self] in
            self?.viewModel?.delegate?.updateAvatar(image: image, participantId: participantId)
        }
    }

    private func create(_ viewModel: MessageRowViewModel) {
        guard self.viewModel?.thread.group == true, !viewModel.calMessage.isMe, let url = viewModel.message.participant?.image else { return }
        if isInQueue(url) { return }
        releaseFromBottom()
        let config = ImageLoaderConfig(url: url)
        let vm = ImageLoaderViewModel(config: config)
        avatarsViewModelsQueue.append(vm)
        vm.onImage = { [weak self, weak vm] image in
            self?.cachedAvatars[url] = image
            self?.updateRow(image, viewModel.message.participant?.id ?? -1)
            if let vm = vm {
                self?.removeViewModel(vm)
            }
        }
        Task { [weak vm] in
            vm?.fetch()
        }
    }

    private func isInQueue(_ url: String) -> Bool {
        avatarsViewModelsQueue.contains(where: { $0.config.url == url })
    }

    private func removeViewModel(_ viewModel: ImageLoaderViewModel) {
        viewModel.clear()
        avatarsViewModelsQueue.removeAll(where: {$0.config.url == viewModel.config.url})
    }

    private func releaseFromBottom() {
        if cachedAvatars.count > maxCache, let firstKey = cachedAvatars.first?.key {
            cachedAvatars.removeValue(forKey: firstKey)
        }
    }
}
