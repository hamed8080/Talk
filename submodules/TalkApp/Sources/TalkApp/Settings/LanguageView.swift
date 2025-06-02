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

    var body: some View {
        List {
            ForEach(TalkModels.Language.languages) { language in
                Button {
                    changeLanguage(language: language)
                } label: {
                    HStack {
                        let isSelected = Locale.preferredLanguages[0] == language.language
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
        .background(Color.App.bgPrimary)
        .listStyle(.plain)
        .normalToolbarView(title: "Settings.language", type: LanguageNavigationValue.self)
    }

    func changeLanguage(language: TalkModels.Language) {
        let bundle = BundleManager().getBundle()
        Language.setLanguageTo(bundle: bundle, language: language)
        Task {
            await container.reset()
            await container.threadsVM.getThreads()
            await container.contactsVM.getContacts()
            NotificationCenter.default.post(name: Notification.Name("RELAOD"), object: nil)
        }
    }
}
