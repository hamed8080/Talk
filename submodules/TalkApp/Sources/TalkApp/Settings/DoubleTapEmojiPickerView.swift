//
//  DoubleTapEmojiPickerView.swift
//  TalkApp
//
//  Created by Hamed Hosseini on 6/28/25.
//

import SwiftUI
import Chat
import TalkViewModels

struct DoubleTapEmojiPickerView: View {
    @State var selectedEmoji: Sticker?
    private var isIpad: Bool { UIDevice.current.userInterfaceIdiom == .pad  }
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVGrid(columns: .init(repeating: .init(.flexible(minimum: 46, maximum: 64)), count: 7), alignment: .center, spacing: 12) {
                ForEach(Sticker.allCases) { sticker in
                    Button {
                        var model = AppSettingsModel.restore()
                        model.doubleTapAction = .specialEmoji(sticker)
                        model.save()
                        AppState.shared.objectsContainer.navVM.removeUIKit()
                    } label: {
                        Text(sticker.emoji)
                            .font(.system(size: 42))
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(selectedEmoji?.rawValue == sticker.rawValue ? Color.App.accent.opacity(0.5) : Color.clear)
                            )
                    }
                }
            }
        }
        .padding(.horizontal, 8)
        .background(Color.App.bgPrimary)
        .normalToolbarView(title: "Settings.DoubleTap.title", innerBack: true, type: String.self)
        .onAppear {
            let action = AppSettingsModel.restore().doubleTapAction
            if case .specialEmoji(let sticker) = action {
                selectedEmoji = sticker
            }
        }
    }
}
