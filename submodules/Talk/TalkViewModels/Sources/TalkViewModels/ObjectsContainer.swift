import Combine
import SwiftUI
import Chat
import TalkModels

@MainActor
public final class ObjectsContainer: ObservableObject {
    public private(set) var cancellableSet: Set<AnyCancellable> = []
    @Published public var userConfigsVM = UserConfigManagerVM.instance
    @Published public var navVM = NavigationModel()
    @Published public var loginVM: LoginViewModel
    @Published public var logVM = LogViewModel()
    @Published public var contactsVM = ContactsViewModel()
    @Published public var threadsVM = ThreadsViewModel()
    @Published public var tagsVM = TagsViewModel()
    @Published public var settingsVM = SettingViewModel()
    @Published public var tokenVM = TokenManager.shared
    @Published public var audioPlayerVM = AVAudioPlayerViewModel()
    @Published public var messagePlayer = AVAudioPlayerViewModel()
    @Published public var appOverlayVM = AppOverlayViewModel()
    @Published public var searchVM = ThreadsSearchViewModel()
    @Published public var archivesVM = ArchiveThreadsViewModel()
    @Published public var errorVM = ErrorHandlerViewModel()
    @Published public var banVM = BanViewModel()
    @Published public var userProfileImageVM: ImageLoaderViewModel!
    public var chatRequestQueue = ChatRequestQueue()

    /// As a result of a bug in the SwiftUI sheet where it can't release the memory, we have to keep a global object and rest its values to default to prevent memory leak unless we end up not receiving server messages.
    @Published public var conversationBuilderVM = ConversationBuilderViewModel()

    public init(delegate: ChatDelegate) {
        loginVM = LoginViewModel(delegate: delegate)
        NotificationCenter.message.publisher(for: .message)
            .compactMap { $0.object as? MessageEventTypes }
            .sink { [weak self] event in
                Task { [weak self] in
                    await self?.onMessageEvent(event)
                }
            }
            .store(in: &cancellableSet)
        NotificationCenter.user.publisher(for: .user)
            .compactMap { $0.object as? UserEventTypes }
            .sink { [weak self] event in
                self?.onUserEvent(event)
            }
            .store(in: &cancellableSet)
        AppState.shared.objectsContainer = self

        let user = userConfigsVM.currentUserConfig?.user
        fetchUserProfile(user: user)
    }

    @MainActor
    public func reset() async {
        AppState.shared.clear()
        await threadsVM.clear()
        await contactsVM.clear()
        tagsVM.clear()
        tagsVM.getTagList()
        navVM.clear()
        await threadsVM.getThreads()
        await contactsVM.getContacts()
        logVM.clearLogs()
        appOverlayVM.clear()
        await conversationBuilderVM.clear()
        userProfileImageVM.clear()
    }

    private func onMessageEvent(_ event: MessageEventTypes) async {
        switch event {
        case .new(let chatResponse):
            if !audioPlayerVM.isPlaying {
                await onNewMessage(chatResponse)
            }
            break
        case .sent(_):
            if !audioPlayerVM.isPlaying {
                await playMessageSound(sent: true)
            }
            break
        default:
            break
        }
    }

    private func onNewMessage(_ response: ChatResponse<Message>) async {
        let notificationSettings = AppSettingsModel.restore().notificationSettings
        if response.result?.conversation?.mute == true { return }
        guard notificationSettings.soundEnable,
              AppState.shared.user?.id != response.result?.ownerId,
              let conversation = response.result?.conversation
        else { return }
        if conversation.group == false, notificationSettings.privateChat.sound {
            await playMessageSound(sent: false)
        } else if conversation.group == true, notificationSettings.group.sound {
            await playMessageSound(sent: false)
        } else if conversation.type?.isChannelType == true, notificationSettings.channel.sound {
            await playMessageSound(sent: false)
        }

        if notificationSettings.vibration {
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        }
    }

    private func playMessageSound(sent: Bool) async {
        if let fileURL = Language.rootBundle?.url(forResource: sent ? "sent_message" : "new_message", withExtension: "mp3") {
            try? messagePlayer.setup(message: nil, fileURL: fileURL, ext: "mp3", category: .ambient)
            messagePlayer.toggle()
        }
    }

    private func onUserEvent(_ event: UserEventTypes) {
        switch event {
        case .user(let chatResponse):
            onUser(chatResponse)
        default:
            break
        }
    }

    private func onUser(_ response: ChatResponse<User>) {
        if response.result != nil {
            fetchUserProfile(user: response.result)
        }
    }

    private func fetchUserProfile(user: User?) {
        let image = user?.image ?? ""
        let httpsImage = image.replacingOccurrences(of: "http://", with: "https://")
        let config = ImageLoaderConfig(url: httpsImage, size: .LARG, userName: String.splitedCharacter(user?.name ?? ""))
        if userProfileImageVM == nil {
            userProfileImageVM = .init(config: config)
        } else {
            userProfileImageVM.updateCondig(config: config)
        }

        // We wait for the cache to fill its properties, due to forceToDownloadFromServer having set to false,
        // we have to wait for init and then the cache is not nil and can find the file
        Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { [weak self] _ in
            if user != nil {
                Task { @MainActor [weak self] in
                    self?.userProfileImageVM.fetch()
                }
            }
        }
    }
}
