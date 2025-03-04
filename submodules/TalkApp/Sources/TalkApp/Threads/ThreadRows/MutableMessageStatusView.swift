//
//  MutableMessageStatusView.swift
//  Talk
//
//  Created by hamed on 5/30/24.
//

import SwiftUI
import TalkModels
import TalkExtensions
import TalkViewModels

struct MutableMessageStatusView: View {
    @EnvironmentObject var thread: CalculatedConversation
    let isSelected: Bool
    
    var body: some View {
        ZStack {
            if let icon = thread.iconStatus {
                let isSeen = icon != MessageHistoryStatics.sentImage
                Image(uiImage: icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: isSeen ? 22 : 12, height: isSeen ? 22 : 12)
                    .foregroundColor(isSelected ? Color.App.white : Color(thread.iconStatusColor ?? .black))
                    .font(.subheadline)
                    .offset(y: -2)
            }
        }
    }
}
