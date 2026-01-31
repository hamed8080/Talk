//
//  DetailTabDownloaderViewModel.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Foundation
import Chat
import Combine
import SwiftUI
import TalkExtensions
import TalkModels

@MainActor
public protocol TabLoadingDelegate {
    func startBottomAnimation(_ animate: Bool)
}

public enum LinkItem: Hashable, Sendable {
    case item(TabRowModel)
    case noResult
}

public enum LinksListSection: Sendable {
    case main
    case noResult
}

@MainActor
public protocol UILinksViewControllerDelegate: AnyObject, TabLoadingDelegate {
    func apply(snapshot: NSDiffableDataSourceSnapshot<LinksListSection, LinkItem>, animatingDifferences: Bool)
}

public enum MusicItem: Hashable, Sendable {
    case item(TabRowModel)
    case noResult
}

public enum MusicsListSection: Sendable {
    case main
    case noResult
}

@MainActor
public protocol UIMusicsViewControllerDelegate: AnyObject, TabLoadingDelegate {
    func apply(snapshot: NSDiffableDataSourceSnapshot<MusicsListSection, MusicItem>, animatingDifferences: Bool)
    func updateProgress(item: TabRowModel)
}

public enum VoiceItem: Hashable, Sendable {
    case item(TabRowModel)
    case noResult
}

public enum VoicesListSection: Sendable {
    case main
    case noResult
}

@MainActor
public protocol UIVoicesViewControllerDelegate: AnyObject, TabLoadingDelegate {
    func apply(snapshot: NSDiffableDataSourceSnapshot<VoicesListSection, VoiceItem>, animatingDifferences: Bool)
    func updateProgress(item: TabRowModel)
}

public enum VideoItem: Hashable, Sendable {
    case item(TabRowModel)
    case noResult
}

public enum VideosListSection: Sendable {
    case main
    case noResult
}

@MainActor
public protocol UIVideosViewControllerDelegate: AnyObject, TabLoadingDelegate {
    func apply(snapshot: NSDiffableDataSourceSnapshot<VideosListSection, VideoItem>, animatingDifferences: Bool)
    func updateProgress(item: TabRowModel)
}

public enum FileItem: Hashable, Sendable {
    case item(TabRowModel)
    case noResult
}

public enum FilesListSection: Sendable {
    case main
    case noResult
}

@MainActor
public protocol UIFilesViewControllerDelegate: AnyObject, TabLoadingDelegate {
    func apply(snapshot: NSDiffableDataSourceSnapshot<FilesListSection, FileItem>, animatingDifferences: Bool)
    func updateProgress(item: TabRowModel)
}

public enum PictureItem: Hashable, Sendable {
    case item(TabRowModel)
    case noResult
}

public enum PicturesListSection: Sendable {
    case main
    case noResult
}

@MainActor
public protocol UIPicturesViewControllerDelegate: AnyObject, TabLoadingDelegate {
    func apply(snapshot: NSDiffableDataSourceSnapshot<PicturesListSection, PictureItem>, animatingDifferences: Bool)
    func updateImage(id: Int, image: UIImage?) 
}

@MainActor
public class DetailTabDownloaderViewModel: ObservableObject {
    public private(set) var messagesModels: ContiguousArray<TabRowModel> = []
    private var conversation: Conversation
    private var offset = 0
    private var cancelable = Set<AnyCancellable>()
    public private(set) var isLoading = false
    public private(set) var hasNext = true
    private let messageType: ChatModels.MessageType
    private let count = 25
    public var itemCount = 3
    private let tabName: String
    private var objectId = UUID().uuidString
    private let DETAIL_HISTORY_KEY: String
    public weak var linksDelegate: UILinksViewControllerDelegate?
    public weak var musicsDelegate: UIMusicsViewControllerDelegate?
    public weak var voicesDelegate: UIVoicesViewControllerDelegate?
    public weak var videosDelegate: UIVideosViewControllerDelegate?
    public weak var filesDelegate: UIFilesViewControllerDelegate?
    public weak var picturesDelegate: UIPicturesViewControllerDelegate?

    public init(conversation: Conversation, messageType: ChatModels.MessageType, tabName: String) {
        DETAIL_HISTORY_KEY = "DETAIL-HISTORY-\(tabName)-KEY-\(objectId)"
        self.tabName = tabName
        self.conversation = conversation
        self.messageType = messageType
        NotificationCenter.message.publisher(for: .message)
            .compactMap { $0.object as? MessageEventTypes }
            .sink { [weak self] event in
                Task { @MainActor [weak self] in
                    guard let self = self else { return }
                    await self.onMessageEvent(event)
                }
            }
            .store(in: &cancelable)
    }

    private func onMessageEvent(_ event: MessageEventTypes) async {
        switch event {
        case let .history(response):
            if !response.cache,
               response.subjectId == conversation.id,
               response.pop(prepend: DETAIL_HISTORY_KEY) != nil,
               let messages = response.result {

                for message in messages {
                    if !self.messagesModels.contains(where: { $0.id == message.id }) {
                        let model = await TabRowModel(message: message)
                        
                        /// Attach the avplayer to show progress form the postion the item is playing,
                        /// then append and attaching it to the list.
                        let activePlayingId = AppState.shared.objectsContainer.audioPlayerVM.message?.id
                        if activePlayingId == message.id {
                            model.itemPlayer = AppState.shared.objectsContainer.audioPlayerVM.item
                        }
                        
                        messagesModels.append(model)
                        registerModelChanges(model)

                        if model.links.isEmpty && model.message.type == .link {
                            messagesModels.removeLast()
                        }
                    }
                }
                self.messagesModels.sort(by: { $0.message.time ?? 0 > $1.message.time ?? 0 })
                
                hasNext = response.hasNext
                isLoading = false
                showLoading(show: false)
                apply()
            }
        default:
            break
        }
    }

    public func isCloseToLastThree(_ message: Message) -> Bool {
        let index = Array<TabRowModel>.Index(messagesModels.count - 3)
        if messagesModels.indices.contains(index), messagesModels[index].id == message.id {
            return true
        } else {
            return false
        }
    }

    public func loadMore() {
        guard let conversationId = conversation.id, conversationId != LocalId.emptyThread.rawValue, !isLoading, hasNext else { return }
        let req: GetHistoryRequest = .init(threadId: conversationId, count: count, messageType: messageType.rawValue, offset: offset)
        RequestsManager.shared.append(prepend: DETAIL_HISTORY_KEY, value: req)
        offset += count
        isLoading = true
        showLoading(show: true)
        apply()
        Task { @ChatGlobalActor in
            ChatManager.activeInstance?.message.history(req)
        }
    }
    
    private func registerModelChanges(_ item: TabRowModel) {
        if let picturesDelegate = picturesDelegate {
            Task {
                await item.prepareThumbnail()
                picturesDelegate.updateImage(id: item.id, image: item.thumbnailImage)
            }
        }
        
        if let videosDelegate = videosDelegate {
            item.$state.sink { newState in
                videosDelegate.updateProgress(item: item)
            }
            .store(in: &cancelable)
        }
        
        if let filesDelegate = filesDelegate {
            item.$state.sink { newState in
                filesDelegate.updateProgress(item: item)
            }
            .store(in: &cancelable)
        }
        
        if let voicesDelegate = voicesDelegate {
            item.$state.sink { newState in
                voicesDelegate.updateProgress(item: item)
            }
            .store(in: &cancelable)
        }
        
        if let musicsDelegate = musicsDelegate {
            item.$state.sink { newState in
                musicsDelegate.updateProgress(item: item)
            }
            .store(in: &cancelable)
        }
    }

    deinit {
#if DEBUG
        print("deinit DetailTabDownloaderViewModel for\(tabName)")
#endif
    }
}

/// Apply right snapshot to right tab type.
extension DetailTabDownloaderViewModel {
    private func apply() {
        if linksDelegate != nil {
            createAndApplyLinkSnapshot()
        } else if picturesDelegate != nil {
            createAndApplyPictureSnapshot()
        } else if videosDelegate != nil {
            createAndApplyVideoSnapshot()
        } else if filesDelegate != nil {
            createAndApplyFileSnapshot()
        } else if musicsDelegate != nil {
            createAndApplyMusicSnapshot()
        } else if voicesDelegate != nil {
            createAndApplyVoiceSnapshot()
        }
    }
}

/// Show loading
extension DetailTabDownloaderViewModel {
    private func showLoading(show: Bool) {
        if linksDelegate != nil {
            linksDelegate?.startBottomAnimation(show)
        } else if picturesDelegate != nil {
            picturesDelegate?.startBottomAnimation(show)
        } else if videosDelegate != nil {
            videosDelegate?.startBottomAnimation(show)
        } else if filesDelegate != nil {
            filesDelegate?.startBottomAnimation(show)
        } else if musicsDelegate != nil {
            musicsDelegate?.startBottomAnimation(show)
        } else if voicesDelegate != nil {
            voicesDelegate?.startBottomAnimation(show)
        }
    }
}

/// Create pictures snapshot
extension DetailTabDownloaderViewModel {
    private func createPicutreSnapshot() -> NSDiffableDataSourceSnapshot<PicturesListSection, PictureItem> {
        let isEmpty = messagesModels.isEmpty
        let isLoadingAndEmpty = isEmpty && isLoading
        
        let items = messagesModels.compactMap({ PictureItem.item($0) })
        var snapshot = NSDiffableDataSourceSnapshot<PicturesListSection, PictureItem>()
        
        if !items.isEmpty {
            snapshot.appendSections([.main])
            snapshot.appendItems(items, toSection: .main)
        } else if !isLoadingAndEmpty {
            snapshot.appendSections([.noResult])
            snapshot.appendItems([.noResult], toSection: .noResult)
        }
        return snapshot
    }
    
    private func createAndApplyPictureSnapshot() {
        let snapshot = createPicutreSnapshot()
        picturesDelegate?.apply(snapshot: snapshot, animatingDifferences: false)
    }
}

/// Create videos snapshot
extension DetailTabDownloaderViewModel {
    private func createVideoSnapshot() -> NSDiffableDataSourceSnapshot<VideosListSection, VideoItem> {
        let isEmpty = messagesModels.isEmpty
        let isLoadingAndEmpty = isEmpty && isLoading
        
        let items = messagesModels.compactMap({ VideoItem.item($0) })
        var snapshot = NSDiffableDataSourceSnapshot<VideosListSection, VideoItem>()
        
        if !items.isEmpty {
            snapshot.appendSections([.main])
            snapshot.appendItems(items, toSection: .main)
        } else if !isLoadingAndEmpty {
            snapshot.appendSections([.noResult])
            snapshot.appendItems([.noResult], toSection: .noResult)
        }
        return snapshot
    }
    
    private func createAndApplyVideoSnapshot() {
        let snapshot = createVideoSnapshot()
        videosDelegate?.apply(snapshot: snapshot, animatingDifferences: false)
    }
}

/// Create files snapshot
extension DetailTabDownloaderViewModel {
    private func createFileSnapshot() -> NSDiffableDataSourceSnapshot<FilesListSection, FileItem> {
        let isEmpty = messagesModels.isEmpty
        let isLoadingAndEmpty = isEmpty && isLoading
        
        let items = messagesModels.compactMap({ FileItem.item($0) })
        var snapshot = NSDiffableDataSourceSnapshot<FilesListSection, FileItem>()
        
        if !items.isEmpty {
            snapshot.appendSections([.main])
            snapshot.appendItems(items, toSection: .main)
        } else if !isLoadingAndEmpty {
            snapshot.appendSections([.noResult])
            snapshot.appendItems([.noResult], toSection: .noResult)
        }
        return snapshot
    }
    
    private func createAndApplyFileSnapshot() {
        let snapshot = createFileSnapshot()
        filesDelegate?.apply(snapshot: snapshot, animatingDifferences: false)
    }
}

/// Create musics snapshot
extension DetailTabDownloaderViewModel {
    private func createMusicSnapshot() -> NSDiffableDataSourceSnapshot<MusicsListSection, MusicItem> {
        let isEmpty = messagesModels.isEmpty
        let isLoadingAndEmpty = isEmpty && isLoading
        
        let items = messagesModels.compactMap({ MusicItem.item($0) })
        var snapshot = NSDiffableDataSourceSnapshot<MusicsListSection, MusicItem>()
        
        if !items.isEmpty {
            snapshot.appendSections([.main])
            snapshot.appendItems(items, toSection: .main)
        } else if !isLoadingAndEmpty {
            snapshot.appendSections([.noResult])
            snapshot.appendItems([.noResult], toSection: .noResult)
        }
        return snapshot
    }
    
    private func createAndApplyMusicSnapshot() {
        let snapshot = createMusicSnapshot()
        musicsDelegate?.apply(snapshot: snapshot, animatingDifferences: false)
    }
}

/// Create voices snapshot
extension DetailTabDownloaderViewModel {
    private func createVoiceSnapshot() -> NSDiffableDataSourceSnapshot<VoicesListSection, VoiceItem> {
        let isEmpty = messagesModels.isEmpty
        let isLoadingAndEmpty = isEmpty && isLoading
        
        let items = messagesModels.compactMap({ VoiceItem.item($0) })
        var snapshot = NSDiffableDataSourceSnapshot<VoicesListSection, VoiceItem>()
        
        if !items.isEmpty {
            snapshot.appendSections([.main])
            snapshot.appendItems(items, toSection: .main)
        } else if !isLoadingAndEmpty {
            snapshot.appendSections([.noResult])
            snapshot.appendItems([.noResult], toSection: .noResult)
        }
        return snapshot
    }
    
    private func createAndApplyVoiceSnapshot() {
        let snapshot = createVoiceSnapshot()
        voicesDelegate?.apply(snapshot: snapshot, animatingDifferences: false)
    }
}

/// Create links snapshot
extension DetailTabDownloaderViewModel {
    private func createLinkSnapshot() -> NSDiffableDataSourceSnapshot<LinksListSection, LinkItem> {
        let isEmpty = messagesModels.isEmpty
        let isLoadingAndEmpty = isEmpty && isLoading
        
        let items = messagesModels.compactMap({ LinkItem.item($0) })
        var snapshot = NSDiffableDataSourceSnapshot<LinksListSection, LinkItem>()
        
        if !items.isEmpty {
            snapshot.appendSections([.main])
            snapshot.appendItems(items, toSection: .main)
        } else if !isLoadingAndEmpty {
            snapshot.appendSections([.noResult])
            snapshot.appendItems([.noResult], toSection: .noResult)
        }
        return snapshot
    }
    
    private func createAndApplyLinkSnapshot() {
        let snapshot = createLinkSnapshot()
        linksDelegate?.apply(snapshot: snapshot, animatingDifferences: false)
    }
}
