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

public final class UserConfigManagerVM: ObservableObject, Equatable {
    public static func == (lhs: UserConfigManagerVM, rhs: UserConfigManagerVM) -> Bool {
        lhs.userConfigs.count == rhs.userConfigs.count
    }

    @Published public var userConfigs: [UserConfig] = []
    @Published public var currentUserConfig: UserConfig?
    public static let instance = UserConfigManagerVM()
    private var queue = DispatchQueue(label: "USER_CONFIG_MANAGER_SERIAL_QUEUE")
    private var bundle: Bundle = .main

    public func setup(bundle: Bundle) {
        self.bundle = bundle
        setup()
    }

    private init() { }

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
        ChatManager.switchToUser(userId: userConfig.user.id ?? -1, bundle: bundle)
    }

    public func createChatObjectAndConnect(userId: Int?, config: ChatConfig, delegate: ChatDelegate?) {
        ChatManager.activeInstance?.dispose()
        ChatManager.instance.createOrReplaceUserInstance(userId: userId, config: config, bundle: bundle)
        ChatManager.activeInstance?.delegate = delegate
        ChatManager.activeInstance?.connect()
    }

    public func switchToUser(_ userConfig: UserConfig, delegate: ChatDelegate) {
        TokenManager.shared.saveSSOToken(ssoToken: userConfig.ssoToken)
        setCurrentUserAndSwitch(userConfig)
        createChatObjectAndConnect(userId: userConfig.user.id, config: userConfig.config, delegate: delegate)
        setup() // to set current user @Published var
    }

    public func onUser(_ user: User) {
        if let config = ChatManager.activeInstance?.config, let ssoToken = TokenManager.shared.getSSOTokenFromUserDefaults() {
            addUserInUserDefaultsIfNotExist(userConfig: .init(user: user, config: config, ssoToken: ssoToken))
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
