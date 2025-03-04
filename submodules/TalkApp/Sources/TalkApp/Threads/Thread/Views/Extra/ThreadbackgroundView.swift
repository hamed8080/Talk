//
//  ThreadbackgroundView.swift
//  Talk
//
//  Created by hamed on 3/7/24.
//

import SwiftUI

struct ThreadbackgroundView: View {
    @Environment(\.colorScheme) var colorScheme
    let threadId: Int
    private let lightColors = [
        Color(red: 220/255, green: 194/255, blue: 178/255),
        Color(red: 234/255, green: 173/255, blue: 120/255),
        Color(red: 216/255, green: 125/255, blue: 78/255)
    ]

    private let darkColors = [
        Color(red: 0/255, green: 0/255, blue: 0/255)
    ]

    var body: some View {
        Image("chat_bg")
            .interpolation(.none)
            .resizable()
            .scaledToFill()
            .id("chat_bg_\(threadId)")
            .background(
                LinearGradient(
                    colors: colorScheme == .dark ? darkColors : lightColors,
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}

struct ThreadbackgroundView_Previews: PreviewProvider {
    static var previews: some View {
        ThreadbackgroundView(threadId: 0)
    }
}
