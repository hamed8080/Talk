import Chat
import Combine
import TalkModels
import Foundation

public extension UserDefaults {
    enum keys: String {
        case userConfigsData = "userConfigsData"
        case userConfigData = "userConfigData"
    }
}

@MainActor
public final class UserConfigManagerVM: ObservableObject, @preconcurrency Equatable {
    public static func == (lhs: UserConfigManagerVM, rhs: UserConfigManagerVM) -> Bool {
        lhs.userConfigs.count == rhs.userConfigs.count
    }

    @Published public var userConfigs: [UserConfig] = []
    @Published public var currentUserConfig: UserConfig?
    public static let instance = UserConfigManagerVM()
    private var queue = DispatchQueue(label: "USER_CONFIG_MANAGER_SERIAL_QUEUE")

    private init() {
        setup()
    }

    private func setup() {
        queue.sync {
            if let data = UserDefaults.standard.data(forKey: UserDefaults.keys.userConfigsData.rawValue), let userConfigs = try? JSONDecoder.instance.decode([UserConfig].self, from: data) {
                self.userConfigs = userConfigs
            }

            if let data = UserDefaults.standard.data(forKey: UserDefaults.keys.userConfigData.rawValue), let currentUserConfig = try? JSONDecoder.instance.decode(UserConfig.self, from: data) {
                self.currentUserConfig = currentUserConfig
                setCurrentUserAndSwitch(currentUserConfig)
            }
        }
    }

    public func addUserInUserDefaultsIfNotExist(userConfig: UserConfig) {
        appendOrReplace(userConfig)
        setCurrentUserAndSwitch(userConfig)
        setup()
    }

    public func appendOrReplace(_ userConfig: UserConfig) {
        var newUserConfigs = userConfigs
        if let index = newUserConfigs.firstIndex(where: { $0.user.id == userConfig.user.id }) {
            newUserConfigs[index] = userConfig
        } else {
            newUserConfigs.append(userConfig)
        }
        UserDefaults.standard.set(newUserConfigs.data, forKey: UserDefaults.keys.userConfigsData.rawValue)
    }

    public func setCurrentUserAndSwitch(_ userConfig: UserConfig) {
        UserDefaults.standard.setValue(userConfig.data, forKey: UserDefaults.keys.userConfigData.rawValue)
        Task { @ChatGlobalActor in
            ChatManager.switchToUser(userId: userConfig.user.id ?? -1)
        }
    }

    public func createChatObjectAndConnect(userId: Int?, config: ChatConfig, delegate: ChatDelegate?) {
        Task { @ChatGlobalActor in
            await ChatManager.activeInstance?.dispose()
            ChatManager.instance.createOrReplaceUserInstance(userId: userId, config: config)
            ChatManager.activeInstance?.delegate = delegate
            await ChatManager.activeInstance?.connect()
        }
    }

    public func switchToUser(_ userConfig: UserConfig, delegate: ChatDelegate) {
        TokenManager.shared.saveSSOToken(ssoToken: userConfig.ssoToken)
        setCurrentUserAndSwitch(userConfig)
        createChatObjectAndConnect(userId: userConfig.user.id, config: userConfig.config, delegate: delegate)
        setup() // to set current user @Published var
    }

    public func onUser(_ user: User) {
        Task { @ChatGlobalActor in
            let config = ChatManager.activeInstance?.config
            let ssoToken = await TokenManager.shared.getSSOTokenFromUserDefaultsAsync()
            await MainActor.run {
                if let config = config, let ssoToken = ssoToken {
                    addUserInUserDefaultsIfNotExist(userConfig: .init(user: user, config: config, ssoToken: ssoToken))
                }
            }
        }
    }

    public func logout(delegate: ChatDelegate) {
        if let index = userConfigs.firstIndex(where: { $0.id == currentUserConfig?.id }) {
            userConfigs.remove(at: index)
            UserDefaults.standard.set(userConfigs.data, forKey: UserDefaults.keys.userConfigsData.rawValue)
            setup()
            if let firstUser = userConfigs.first {
                switchToUser(firstUser, delegate: delegate)
            } else {
                // Remove last user config from userDefaults
                currentUserConfig = nil
                userConfigs = []
                UserDefaults.standard.removeObject(forKey: UserDefaults.keys.userConfigData.rawValue)
            }
        }
    }

    public func updateToken(_ ssoToken: SSOTokenResponse) {
        if var currentUserConfig {

            if let index = userConfigs.firstIndex(where: {$0.id == currentUserConfig.id}) {
                userConfigs[index].updateSSOToken(ssoToken)
                UserDefaults.standard.set(userConfigs.data,forKey: UserDefaults.keys.userConfigsData.rawValue)
            }

            currentUserConfig.updateSSOToken(ssoToken)
            self.currentUserConfig = currentUserConfig
            UserDefaults.standard.set(currentUserConfig.data, forKey: UserDefaults.keys.userConfigData.rawValue)
        }
    }
}
