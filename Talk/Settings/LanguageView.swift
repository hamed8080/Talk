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
    @State private var restart: Bool = false
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
                            .font(.iransansBoldBody)
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
        .navigationBarBackButtonHidden(true)
        .alert("Settings.restartToChangeLanguage", isPresented: $restart) {
            Button {
                restart = true
            } label: {
                Text("General.close")
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .navigation) {
                NavigationBackButton {
                    AppState.shared.navViewModel?.remove(type: LanguageNavigationValue.self)
                }
            }

            ToolbarItem(placement: .principal) {
                Text("Settings.language")
                    .fixedSize()
                    .font(.iransansBoldSubheadline)
            }
        }
    }

    func changeLanguage(language: TalkModels.Language) {
        selectedLanguage = language.language
        UserDefaults.standard.set([language.identifier], forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()
        restart = true
    }
}

struct LanguageView_Previews: PreviewProvider {
    static var previews: some View {
        LanguageView(container: .init(delegate: ChatManager.activeInstance!.delegate!))
    }
}
