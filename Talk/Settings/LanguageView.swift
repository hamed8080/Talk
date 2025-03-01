//
//  LanguageView.swift
//  Talk
//
//  Created by hamed on 10/30/23.
//

import SwiftUI
import TalkViewModels
import Chat
import TalkUI
import Foundation
import TalkModels

struct LanguageView: View {
    let container: ObjectsContainer
    @State private var selectedLanguage = Locale.preferredLanguages[0]

    var body: some View {
        List {
            ForEach(TalkModels.Language.languages) { language in
                Button {
                    changeLanguage(language: language)
                } label: {
                    HStack {
                        let isSelected = selectedLanguage == language.language
                        RadioButton(visible: .constant(true), isSelected: Binding(get: {isSelected}, set: {_ in})) { selected in
                            changeLanguage(language: language)
                        }
                        Text(language.text)
                            .font(.fBoldBody)
                            .padding()
                        Spacer()
                    }
                    .frame(height: 48)
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                .frame(height: 48)
                .frame(minWidth: 0, maxWidth: .infinity)
                .buttonStyle(.plain)
                .listRowBackground(Color.App.bgPrimary)
            }
        }
        .animation(.easeInOut, value: selectedLanguage)
        .background(Color.App.bgPrimary)
        .listStyle(.plain)
        .normalToolbarView(title: "Settings.language", type: LanguageNavigationValue.self)
    }

    func changeLanguage(language: TalkModels.Language) {
        selectedLanguage = language.language
        UserDefaults.standard.set([language.identifier], forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()
        Task {
            await container.reset()
            reloadApp()
        }
    }
    
    private func reloadApp() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
        Language.onChangeLanguage()
        let window = UIWindow(windowScene: windowScene)
        let contentView = HomeContentView()
            .font(.iransansBody)
        window.rootViewController = CustomUIHostinViewController(rootView: contentView)
        UIApplication.shared.delegate?.window??.rootViewController = window.rootViewController
        (windowScene.delegate as? SceneDelegate)?.window = window
        window.makeKeyAndVisible()
    }
}
