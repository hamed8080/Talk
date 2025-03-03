//
//  AppDelegate.swift
//  Talk
//
//  Created by Hamed Hosseini on 5/27/21.
//

import TalkViewModels
import UIKit
import TalkModels

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {

    override init() {
        super.init()
        setFirstOpenningLanguage()
    }

    class var shared: AppDelegate! {
        UIApplication.shared.delegate as? AppDelegate
    }

    func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        ChatDelegateImplementation.sharedInstance.initialize()
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options _: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_: UIApplication, didDiscardSceneSessions _: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

    private func setFirstOpenningLanguage() {
        if UserDefaults.standard.bool(forKey: "setFirstOpenningLanguaged") == true { return }
        if let language = Language.languages.first(where: {$0.identifier == "ZmFfSVI=".fromBase64()}) {
            UserDefaults.standard.set([language.identifier], forKey: "AppleLanguages")
            UserDefaults.standard.set(true, forKey: "setFirstOpenningLanguaged")
            UserDefaults.standard.synchronize()
        }
    }
}
