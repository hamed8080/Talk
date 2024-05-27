//
//  SupportView.swift
//  Talk
//
//  Created by hamed on 10/14/23.
//

import SwiftUI
import TalkViewModels
import TalkModels

struct SupportView: View {
    @Environment(\.colorScheme) var scheme

    var body: some View {
        VStack(alignment: .center, spacing: 16) {
            Image("talk_logo")
                .resizable()
                .scaledToFit()
                .frame(width: 52, height: 52)
                .foregroundStyle(Color.App.accent)
                .padding(.bottom, 8)

            Text("Support.title")
                .font(.iransansSubtitle)
                .fontWeight(.bold)
                .foregroundStyle(Color.App.textPrimary)

            Text("Support.aboutUsText")
                .multilineTextAlignment(.leading)
                .lineSpacing(5)
                .foregroundStyle(Color.App.textPrimary)
            let isIpad = UIDevice.current.userInterfaceIdiom  == .pad

            Rectangle()
                .fill(Color.clear)
                .frame(height: 96)
            Text("Support.callDetail")
                .foregroundStyle(Color.App.textPrimary)
            HStack(spacing: 0) {
                Link(destination: URL(string: "\(isIpad ? "facetime" : "tel"):021-91033000")!) {
                    Text("Support.number")
                }
                Spacer()
            }
            .foregroundStyle(Color.App.textSecondary)
            .padding(.leading, 8)

            Spacer()
        }
        .font(.iransansBody)
        .padding(EdgeInsets(top: 16, leading: 24, bottom: 30, trailing: 24))
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
        .background(Color.App.bgPrimary)
        .normalToolbarView(title: "Settings.about", type: SupportNavigationValue.self)
    }
}

struct SupportView_Previews: PreviewProvider {
    static var previews: some View {
        SupportView()
    }
}
