//
//  ListSectionButton.swift
//  TalkUI
//
//  Created by hamed on 2/20/22.
//

import SwiftUI

public struct ListSectionButton: View {
    let imageName: String?
    let title: String
    let color: Color
    let showDivider: Bool
    let shownavigationButton: Bool
    let trailingView: AnyView?
    let action: (() -> ())?

    public init(imageName: String?,
                title: String,
                color: Color,
                showDivider: Bool = true,
                shownavigationButton: Bool = true,
                trailingView: AnyView? = nil,
                action: (() -> Void)? = nil) {
        self.imageName = imageName
        self.title = title
        self.color = color
        self.showDivider = showDivider
        self.action = action
        self.trailingView = trailingView
        self.shownavigationButton = shownavigationButton
    }

    public var body: some View {
        Button {
            action?()
        } label: {
            VStack(alignment: .leading) {
                HStack(spacing: 16) {
                    if let imageName = imageName {
                        HStack {
                            Image(systemName: imageName)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 16, height: 16)
                                .foregroundColor(.white)
                        }
                        .frame(width: 28, height: 28)
                        .background(color)
                        .clipShape(RoundedRectangle(cornerRadius:(8)))
                    }

                    Text(title)
                    Spacer()
                    if let trailingView {
                        trailingView
                    }
                    if shownavigationButton {
                        Image(systemName: "chevron.forward")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 12, height: 12)
                            .foregroundStyle(.gray.opacity(0.8))
                    }
                }
                if showDivider {
                    Rectangle()
                        .fill(.gray.opacity(0.35))
                        .frame(height: 0.5)
                        .padding([.leading])
                }
            }
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 36, alignment: .leading)
            .contentShape(Rectangle())
            .padding(EdgeInsets(top: 12, leading: 16, bottom: showDivider ? 0 : 12, trailing: 16))
        }
        .buttonStyle(ListSectionButtonStyle())
        .contentShape(Rectangle())
    }
}

struct ListSectionButtonStyle: ButtonStyle {

    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? Color.App.bgSecondary : Color.clear)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

struct ListSectionButton_Previews: PreviewProvider {
    static var previews: some View {
        ListSectionButton(imageName: "TEST", title: "TIITLE", color: .red)
    }
}
