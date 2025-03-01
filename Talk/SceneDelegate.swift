//
//  SceneDelegate.swift
//  Talk
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Chat
import SwiftUI
import TalkUI
import TalkViewModels
import UIKit
import BackgroundTasks
import TalkModels
import Logger

@MainActor
final class SceneDelegate: UIResponder, UIWindowSceneDelegate, UIApplicationDelegate {
    var window: UIWindow?
    private var backgroundTaskID: UIBackgroundTaskIdentifier?

    func scene(_ scene: UIScene, willConnectTo _: UISceneSession, options _: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).

        // Create the SwiftUI view that provides the window contents.
        let contentView = HomeContentView()
            .font(.fBody)
        TokenManager.shared.initSetIsLogin()

        // Use a UIHostingController as window root view controller.
        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)
            window.rootViewController = CustomUIHostinViewController(rootView: contentView) // CustomUIHosting is Needed for change status bar color per page
            self.window = window
            window.makeKeyAndVisible()
        }
        
        // MARK: Registering Launch Handlers for Tasks
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "\(Bundle.main.bundleIdentifier!).refreshToken", using: nil) { [weak self] task in
            // Downcast the parameter to an app refresh task as this identifier is used for a refresh request.
            if let task = task as? BGAppRefreshTask {
                self?.handleTaskRefreshToken(task)
            }
        }
    }

    func scene(_: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url else { return }
        if let threadId = url.widgetThreaId {
            AppState.shared.showThread(.init(id: threadId))
        } else if let userName = url.openThreadUserName {
            AppState.shared.openThreadWith(userName: userName)
        } else if let decodedOpenURL = url.decodedOpenURL {
            let talk = AppState.shared.spec.server.talk
            let talkJoin = "\(talk)\(AppState.shared.spec.paths.talk.join)"
            if decodedOpenURL.absoluteString.contains(talkJoin) {
                /// Show join to public group dialog
                let publicName = decodedOpenURL.absoluteString.replacingOccurrences(of: talkJoin, with: "").replacingOccurrences(of: "\u{200f}", with: "")
                AppState.shared.objectsContainer.appOverlayVM.dialogView = AnyView(JoinToPublicConversationDialog(publicGroupName: publicName))
            } else {
                /// Open up the browser
                AppState.shared.openURL(url: decodedOpenURL)
            }
        }
    }

    func sceneDidDisconnect(_: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_: UIScene) {
        AppState.shared.updateWindowMode()
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
        AppState.shared.lifeCycleState = .active
    }

    func sceneWillResignActive(_: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
        AppState.shared.updateWindowMode()
        AppState.shared.lifeCycleState = .inactive
    }

    func sceneWillEnterForeground(_: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
        AppState.shared.lifeCycleState = .foreground
    }

    func sceneDidEnterBackground(_: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
        AppState.shared.lifeCycleState = .background
        Task {
            await scheduleAppRefreshToken()
        }

        self.backgroundTaskID = UIApplication.shared.beginBackgroundTask(withName: "START_REQUESTING_MORE_BG_TIME") { [weak self] in
            self?.endBGTask()
        }

        /// We request only 10 seconds, to keep the socket open.
        /// More than this value leads to iOS getting suspicious and terminating the app afterward.
        Timer.scheduledTimer(withTimeInterval: min(10, UIApplication.shared.backgroundTimeRemaining), repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.endBGTask()
            }
        }
    }

    func endBGTask() {
        if let backgroundTaskID = backgroundTaskID {
            UIApplication.shared.endBackgroundTask(backgroundTaskID)
            self.backgroundTaskID = UIBackgroundTaskIdentifier.invalid
        }
    }

    private func scheduleAppRefreshToken() async {
        if let ssoToken = await TokenManager.shared.getSSOTokenFromUserDefaultsAsync(), let createDate = TokenManager.shared.getCreateTokenDate() {
            let timeToStart = createDate.advanced(by: Double(ssoToken.expiresIn - 50)).timeIntervalSince1970 - Date().timeIntervalSince1970
            let request = BGAppRefreshTaskRequest(identifier: "\(Bundle.main.bundleIdentifier!).refreshToken")
            request.earliestBeginDate = Date(timeIntervalSince1970: timeToStart)
            do {
                try BGTaskScheduler.shared.submit(request)
            } catch {
#if DEBUG
                print("Could not schedule app refresh(Maybe you should run it on a real device): \(error)")
#endif
            }
        }
    }

    private func handleTaskRefreshToken(_ task: BGAppRefreshTask) {
        let log = Log(prefix: "TALK_APP", time: .now, message: "Start a new Task in handleTaskRefreshToken method", level: .error, type: .sent, userInfo: nil)        
        Task { @MainActor in
            self.log(log)
            do {
                try await TokenManager.shared.getNewTokenWithRefreshToken()
                await scheduleAppRefreshToken() /// Reschedule again when user receive a token.
            } catch {
                if let error = error as? AppErrors, error == AppErrors.revokedToken {
                    await ChatDelegateImplementation.sharedInstance.logout()
                }
            }
        }
    }

    private func log(_ log: Log) {
#if DEBUG
        NotificationCenter.logs.post(name: .logs, object: log)
#endif
    }
}
