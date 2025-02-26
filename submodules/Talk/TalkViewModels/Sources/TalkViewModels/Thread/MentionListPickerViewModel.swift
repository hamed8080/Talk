//
//  MentionListPickerViewModel.swift
//  TalkViewModels
//
//  Created by hamed on 10/22/22.
//

import Foundation
import Chat
import Combine

@MainActor
public final class MentionListPickerViewModel {
    private weak var viewModel: ThreadViewModel?
    private var thread: Conversation? { viewModel?.thread }
    private var threadId: Int { thread?.id ?? -1 }
    @Published public var text: String = ""
    public private(set) var mentionList: ContiguousArray<Participant> = .init()
    private var cancelable: Set<AnyCancellable> = []
    private var searchText: String? = nil
    @MainActor public var lazyList = LazyListViewModel()
    private var objectId = UUID().uuidString
    private let MENTION_PARTICIPANTS_KEY: String
    public private(set) var avatarVMS: [Int: ImageLoaderViewModel] = [:]
    public var onImageParticipant: ((Participant) -> ())?

    public init() {
       MENTION_PARTICIPANTS_KEY = "MENTION-PARTICIPANTS-KEY-\(objectId)"
    }

    public func setup(viewModel: ThreadViewModel) {
        self.viewModel = viewModel
        setupNotificationObservers()
    }

    private func setupNotificationObservers() {
        $text
            .debounce(for: 0.5, scheduler: RunLoop.main)
            .sink { [weak self] newValue in
                Task { [weak self] in
                    await self?.searchForParticipantInMentioning(newValue)
                }
            }
            .store(in: &cancelable)

        NotificationCenter.participant.publisher(for: .participant)
            .compactMap { $0.object as? ParticipantEventTypes }
            .sink { [weak self] event in
                Task { [weak self] in
                    await self?.onParticipantsEvent(event)
                }
            }
            .store(in: &cancelable)
    }

    @MainActor
    public func searchForParticipantInMentioning(_ text: String) async {
        if thread?.group == false || thread?.group == nil { return }
        /// remove the hidden RTL character for forcing the UITextView to write from right to left.
        let text = text.replacingOccurrences(of: "\u{200f}", with: "")
        if text.last == "@" {
            // Fetch some data to show if the user typed an @.
            searchText = nil
            lazyList.reset()
            await getParticipants()
        } else if text.matches(char: "@")?.last != nil, text.split(separator: " ").last?.first == "@", text.last != " " {
            searchText = text.split(separator: " ").last?.replacingOccurrences(of: "@", with: "")
            lazyList.reset()
            await getParticipants()
        } else {
            let mentionListWasFill = mentionList.count > 0
            mentionList = []
            for item in avatarVMS.enumerated() {
                item.element.value.clear()
            }
            avatarVMS.removeAll()
            if mentionListWasFill {
                viewModel?.delegate?.onMentionListUpdated()
            }
        }
    }

    @MainActor
    func onParticipants(_ response: ChatResponse<[Participant]>) async {
        /// We have to check threadId when forwarding messages to prevent the previous thread catch the result.
        if !response.cache, response.subjectId == viewModel?.threadId, response.pop(prepend: MENTION_PARTICIPANTS_KEY) != nil, let participants = response.result {
            if lazyList.offset == 0 {
                self.mentionList.removeAll()
                self.mentionList = .init(participants)
            } else {
                lazyList.setHasNext(response.hasNext)
                self.mentionList.append(contentsOf: participants)
            }
            lazyList.setLoading(false)
            mentionList.removeAll(where: {$0.id == AppState.shared.user?.id})
            viewModel?.delegate?.onMentionListUpdated()
            prepareAvatarViewModels(participants)
        }
    }

    public func onParticipantsEvent(_ event: ParticipantEventTypes) async {
        switch event {
        case .participants(let response):
            await onParticipants(response)
        default:
            break
        }
    }

    private func prepareAvatarViewModels(_ participants: [Participant]) {
        participants.forEach { participant in
            if !avatarVMS.contains(where: {$0.key == participant.id}) {
                let userName = String.splitedCharacter(participant.name ?? participant.username ?? "")
                let config = ImageLoaderConfig(url: participant.image ?? "", userName: userName)
                let vm = ImageLoaderViewModel(config: config)
                avatarVMS[participant.id ?? 0] = vm
                vm.fetch()
                vm.onImage = { [weak self, vm] image in
                    Task { @MainActor in
                        if vm.isImageReady {
                            self?.onImageParticipant?(participant)
                        }
                    }
                }
            }
        }
    }

    @MainActor
    private func getParticipants() async {
        lazyList.setLoading(true)
        viewModel?.delegate?.onMentionListUpdated()
        let count = lazyList.count
        let offset = lazyList.offset
        let req = ThreadParticipantRequest(threadId: threadId, offset: offset, count: count, name: searchText)
        RequestsManager.shared.append(prepend: MENTION_PARTICIPANTS_KEY, value: req)
        Task { @ChatGlobalActor in
            ChatManager.activeInstance?.conversation.participant.get(req)
        }
    }

    public func loadMore() async {
        if await !lazyList.canLoadMore() { return }
        lazyList.prepareForLoadMore()
        await getParticipants()
    }

    public func cancelAllObservers() {
        cancelable.forEach { cancelable in
            cancelable.cancel()
        }
    }
}
