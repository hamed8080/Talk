//
//  DoubleTapSettingView.swift
//  Talk
//
//  Created by Hamed Hosseini on 12/15/24.
//

import SwiftUI
import TalkUI
import TalkViewModels

struct DoubleTapSettingView: View {
    @EnvironmentObject var navModel: NavigationModel
    @State private var selectedMode: AppSettingsModel.DoubleTapAction? = nil

    var body: some View {
        List {
            ListSectionButton(imageName: nil, title: "Settings.DoubleTap.noAction", showDivider: true, shownavigationButton: false) {
                var model = AppSettingsModel.restore()
                model.doubleTapAction = nil
                model.save()
                selectedMode = nil
            }
            .listRowInsets(.zero)
            .listRowBackground(Color.App.bgPrimary)
            .listRowSeparatorTint(Color.App.dividerPrimary)
            .overlay(alignment: .trailing) {
                if selectedMode == nil {
                    checkMarkView
                }
            }
            
            ListSectionButton(imageName: nil, title: "Settings.DoubleTap.selectEmoji", showDivider: true, shownavigationButton: false) {
                navModel.wrapAndPush(view: DoubleTapEmojiPickerView())
            }
            .listRowInsets(.zero)
            .listRowBackground(Color.App.bgPrimary)
            .listRowSeparatorTint(Color.App.dividerPrimary)
            .overlay(alignment: .trailing) {
                if case .specialEmoji(let sticker) = selectedMode {
                    HStack(spacing: 8) {
                        Text(sticker.emoji)
                            .font(.system(size: 32))
                        checkMarkView
                    }
                }
            }
            
            ListSectionButton(imageName: nil, title: "Settings.DoubleTap.reply", showDivider: false, shownavigationButton: false) {
                var model = AppSettingsModel.restore()
                model.doubleTapAction = .reply
                model.save()
                selectedMode = .reply
            }
            .listRowInsets(.zero)
            .listRowBackground(Color.App.bgPrimary)
            .listRowSeparatorTint(Color.App.dividerPrimary)
            .overlay(alignment: .trailing) {
                if case .reply = selectedMode {
                    checkMarkView
                }
            }
        }
        .font(Font.normal(.body))
        .environment(\.defaultMinListRowHeight, 8)
        .background(Color.App.bgPrimary)
        .listStyle(.plain)
        .normalToolbarView(title: "Settings.DoubleTap.title", innerBack: true, type: String.self)
        .onAppear {
            selectedMode = AppSettingsModel.restore().doubleTapAction
        }
    }
    
    private var checkMarkView: some View {
        Image(systemName: "checkmark")
            .resizable()
            .scaledToFit()
            .frame(width: 16, height: 16)
            .foregroundStyle(Color.App.accent)
            .padding(.trailing, 16)
    }
}

#Preview {
    ManageSessionsSection()
}
