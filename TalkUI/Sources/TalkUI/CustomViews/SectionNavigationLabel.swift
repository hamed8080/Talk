//
//  SectionNavigationLabel.swift
//  TalkUI
//
//  Created by hamed on 2/20/22.
//

import SwiftUI

public struct SectionNavigationLabel: View {
    @Environment(\.colorScheme) var scheme
    let imageName: String
    let title: String
    let color: Color

    public init(imageName: String, title: String, color: Color) {
        self.imageName = imageName
        self.title = title
        self.color = color
    }

    public var body: some View {
        HStack {
            HStack {
                Image(systemName: imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                    .foregroundColor(.white)
            }
            .padding(4)
            .frame(width: 28, height: 28)
            .background(color)
            .cornerRadius(8, corners: .allCorners)

            Text(String(localized: .init(title)))
                .foregroundColor(scheme == .dark ? .white : .black)
        }
        .padding([.top, .bottom], 5)
    }
}
struct SectionNavigationLabel_Previews: PreviewProvider {
    static var previews: some View {
        SectionNavigationLabel(imageName: "trash", title: "DELETE", color: .red)
    }
}
