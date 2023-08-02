//
//  TagsViewModel.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Chat
import Combine
import ChatModels
import ChatCore
import SwiftUI
import ChatAppModels
import ChatDTO

public final class TagsViewModel: ObservableObject {
    public var tags: [Tag] = []
    @Published public var selectedTag: Tag?
    @Published public var isLoading = false
    @Published public var showAddParticipants = false
    public private(set) var firstSuccessResponse = false
    private var cancelable: Set<AnyCancellable> = []
    private var requests: [String: Any] = [:]

    public init() {
        AppState.shared.$connectionStatus
            .sink{ [weak self] status in
                self?.onConnectionStatusChanged(status)
            }
            .store(in: &cancelable)
        NotificationCenter.default.publisher(for: .tag)
            .compactMap { $0.object as? TagEventTypes }
            .sink { [weak self] value in
                self?.onTagEvent(value)
            }
            .store(in: &cancelable)
        getTagList()
    }

    private func onTagEvent(_ event: TagEventTypes) {
        switch event {
        case .tags(let chatResponse):
            onTags(chatResponse)
        case .created(let chatResponse):
            onCreateTag(chatResponse)
        case .deleted(let chatResponse):
            onDeleteTag(chatResponse)
        case .edited(let chatResponse):
            onEditTag(chatResponse)
        case .added(let chatResponse):
            onAddTagParticipant(chatResponse)
        default:
            break
        }
    }

    public func onConnectionStatusChanged(_ status: Published<ConnectionStatus>.Publisher.Output) {
        if firstSuccessResponse == false, status == .connected {
            getTagList()
        }
    }

    public func onTags(_ response: ChatResponse<[Tag]>) {
        if let tags = response.result {
            appendTags(tags: tags)
        }

        if !response.cache {
            firstSuccessResponse = true
        }

        isLoading = false
        animateObjectWillChange()
    }

    public func getTagList() {
        ChatManager.activeInstance?.tag.all()
    }

    public func deleteTag(_ tag: Tag) {
        let req = DeleteTagRequest(id: tag.id)
        ChatManager.activeInstance?.tag.delete(req)
    }

    private func onDeleteTag(_ response: ChatResponse<Tag>) {
        if let tag = response.result {
            self.removeTag(tag)
        }
    }

    private func onCreateTag(_ response: ChatResponse<Tag>) {
        if let tag = response.result {
            self.appendTags(tags: [tag])
        }
        isLoading = false
    }

    public func refresh() {
        clear()
        getTagList()
    }

    public func clear() {
        tags = []
        selectedTag = nil
    }

    public func createTag(name: String) {
        isLoading = true
        let req = CreateTagRequest(tagName: name)
        ChatManager.activeInstance?.tag.create(req)
    }

    public func addThreadToTag(tag: Tag, threadId: Int?) {
        if let threadId = threadId {
            isLoading = true
            ChatManager.activeInstance?.tag.add(.init(tagId: tag.id, threadIds: [threadId]))
        }
    }

    private func onAddTagParticipant(_ response: ChatResponse<[TagParticipant]>) {
        if let tagParticipants = response.result, let tagId = tagParticipants.first?.tagId {
            addParticipant(tagId, tagParticipants)
        }
        isLoading = false
    }

    public func toggleSelectedTag(tag: Tag, isSelected: Bool) {
        setSelectedTag(tag: tag, isSelected: isSelected)
    }

    public func editTag(tag: Tag) {
        let req = EditTagRequest(id: tag.id, tagName: tag.name)
        ChatManager.activeInstance?.tag.edit(req)
    }

    private func onEditTag(_ response: ChatResponse<Tag>) {
        if let tag = response.result {
            editedTag(tag)
        }
    }

    public func deleteTagParticipant(_ tagId: Int, _ tagParticipant: TagParticipant) {
        let req = RemoveTagParticipantsRequest(tagId: tagId, tagParticipants: [tagParticipant])
        requests[req.uniqueId] = req
        ChatManager.activeInstance?.tag.remove(req)
    }

    private func onRemoveTagParticipant(_ response: ChatResponse<[TagParticipant]>) {
        if let tagParticipants = response.result, let uniqueId = response.uniqueId, let request = requests[uniqueId] as? RemoveTagParticipantsRequest {
            removeParticipants(request.tagId, tagParticipants)
            requests.removeValue(forKey: uniqueId)
        }
        isLoading = false
    }

    public func appendTags(tags: [Tag]) {
        // remove older data to prevent duplicate on view
        tags.forEach { tag in
            if let oldIndex = self.tags.firstIndex(where: { $0.id == tag.id }) {
                self.tags[oldIndex] = tag
            } else {
                self.tags.append(tag)
            }
        }
    }

    public func setSelectedTag(tag: Tag?, isSelected _: Bool) {
        selectedTag = tag
    }

    public func removeTag(_ tag: Tag) {
        tags.removeAll(where: { $0.id == tag.id })
    }

    public func editedTag(_ tag: Tag) {
        let tag = Tag(id: tag.id, name: tag.name, active: tag.active, tagParticipants: tags.first(where: { $0.id == tag.id })?.tagParticipants)
        removeTag(tag)
        appendTags(tags: [tag])
    }

    public func removeParticipants(_ tagId: Int, _ tagParticipants: [TagParticipant]) {
        if let tag = tags.first(where: { $0.id == tagId }) {
            tag.tagParticipants?.removeAll(where: { cached in tagParticipants.contains(where: { cached.id == $0.id }) })
            let tagParticipants = tag.tagParticipants
            let tag = Tag(id: tagId, name: tag.name, active: tag.active, tagParticipants: tagParticipants)
            removeTag(tag)
            appendTags(tags: [tag])
        }
    }

    public func addParticipant(_ tagId: Int, _ participants: [TagParticipant]) {
        if let tagIndex = tags.firstIndex(where: { $0.id == tagId }) {
            tags[tagIndex].tagParticipants?.append(contentsOf: participants)
        }
    }
}
