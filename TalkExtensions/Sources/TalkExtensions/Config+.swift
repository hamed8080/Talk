import TalkModels
import Foundation
import Logger
import Chat
import Async

public extension Config {

    static func mainConfig() -> Config {
        let config = Config(socketAddresss: AppRoutes.socketAddress,
                            ssoHost: AppRoutes.ssoHost,
                            platformHost: AppRoutes.platformHost,
                            fileServer: AppRoutes.podspace,
                            peerName: AppRoutes.peerName,
                            debugToken: nil,
                            server: "main")
        return config
    }

    static func getConfig(_ server: ServerTypes = .integration) -> Config? {
        #if DEBUG
        guard let path = Bundle.main.path(forResource: "Config", ofType: ".json") else { return nil }
        if let data = try? Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe) {
            let configs = try? JSONDecoder().decode([Config].self, from: data)
            let selectedConfig = configs?.first { $0.server == String(describing: server) }
            return selectedConfig
        } else {
            return nil
        }
        #endif
        return mainConfig()
    }

    static func config(token: String, selectedServerType: ServerTypes) -> ChatConfig {
        guard let config = Config.getConfig(selectedServerType) else { fatalError("couldn't find config in the json file!") }
        let callConfig = CallConfigBuilder()
            .callTimeout(20)
            .targetVideoWidth(640)
            .targetVideoHeight(480)
            .maxActiveVideoSessions(2)
            .targetFPS(15)
            .build()
        let asyncLoggerConfig = LoggerConfig(prefix: "ASYNC_SDK",
                                             logServerURL: AppRoutes.chatLogger,
                                             logServerMethod: "PUT",
                                             persistLogsOnServer: true,
                                             isDebuggingLogEnabled: true,
                                             sendLogInterval: 5 * 60,
                                             logServerRequestheaders: ["Authorization": "Basic Y2hhdDpjaGF0MTIz", "Content-Type": "application/json"])
        let chatLoggerConfig = LoggerConfig(prefix: "CHAT_SDK",
                                            logServerURL: AppRoutes.chatLogger,
                                            logServerMethod: "PUT",
                                            persistLogsOnServer: true,
                                            isDebuggingLogEnabled: true,
                                            sendLogInterval: 5 * 60,
                                            logServerRequestheaders: ["Authorization": "Basic Y2hhdDpjaGF0MTIz", "Content-Type": "application/json"])
        let asyncConfig = try! AsyncConfigBuilder()
            .socketAddress(config.socketAddresss)
            .reconnectCount(Int.max)
            .reconnectOnClose(true)
            .appId("PodChat")
            .peerName(config.peerName)
            .loggerConfig(asyncLoggerConfig)
            .build()
        let chatConfig = ChatConfigBuilder(asyncConfig)
            .callConfig(callConfig)
            .token(token)
            .ssoHost(config.ssoHost)
            .platformHost(config.platformHost)
            .fileServer(config.fileServer)
            .enableCache(true)
            .msgTTL(800_000) // for integeration server need to be long time
            .persistLogsOnServer(true)
            .appGroup(AppGroup.group)
            .loggerConfig(chatLoggerConfig)
            .mapApiKey("8b77db18704aa646ee5aaea13e7370f4f88b9e8c")
            .mapServer(AppRoutes.map)
            .podSpaceFileServerAddress(AppRoutes.podspace)
            .typeCodes([.init(typeCode: "default", ownerId: nil)])
            .build()
        return chatConfig
    }

    static func serverType(config: ChatConfig?) -> ServerTypes? {
        if config?.asyncConfig.socketAddress == Config.getConfig(.main)?.socketAddresss {
            return .main
        } else if config?.asyncConfig.socketAddress == Config.getConfig(.sandbox)?.socketAddresss {
            return .sandbox
        } else if config?.asyncConfig.socketAddress == Config.getConfig(.integration)?.socketAddresss {
            return .integration
        } else {
            return nil
        }
    }
}
