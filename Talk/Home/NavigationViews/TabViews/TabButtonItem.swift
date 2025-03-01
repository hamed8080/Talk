//
//  TabButtonItem.swift
//  Talk
//
//  Created by hamed on 9/14/23.
//

import SwiftUI

struct TabButtonItem: View {
    var title: String
    var image: Image?
    var imageView: (any View)?
    let contextMenu: (any View)?
    var isSelected: Bool
    var showSelectedDivider: Bool
    var onClick: () -> Void

    var body: some View {
        VStack {
            if let image {
                image
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundColor(isSelected ? Color.App.accent : Color.App.iconSecondary)
            } else if let imageView {
                AnyView(imageView)
                    .frame(width: 24, height: 24)
                    .foregroundColor(isSelected ? Color.App.accent : Color.App.iconSecondary)
            }

            Text(title)
                .font(.fBoldCaption)
                .foregroundColor(isSelected ? Color.App.accent : Color.App.iconSecondary)

            if showSelectedDivider, isSelected {
                Rectangle()
                    .fill(Color.App.accent)
                    .frame(width: 72, height: 3)
                    .cornerRadius(2, corners: [.topLeft, .topRight])
            }
        }
        .contentShape(Rectangle())
        .padding(4)
        .contextMenu {
            if let contextMenu {
                AnyView(contextMenu)
            }
        }
        .onTapGesture {
            withAnimation(.easeInOut) {
                onClick()
            }
        }
    }
}

struct TabItem_Previews: PreviewProvider {
    static var previews: some View {
        TabButtonItem(title: "", image: Image(systemName: ""), contextMenu: nil, isSelected: false, showSelectedDivider: true) {}
    }
}
