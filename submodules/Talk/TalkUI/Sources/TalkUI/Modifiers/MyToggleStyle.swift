//
//  MyToggleStyle.swift
//  TalkUI
//
//  Created by Hamed Hosseini on 11/30/21.
//

import SwiftUI

struct ToggleShape: Shape {

    func path(in rect: CGRect) -> Path {
        Path { path in
            let roundedCorner: CGFloat = rect.height
            let roundeedRect = CGRect(x: 0, y: 0, width: rect.width, height: rect.height)
            path.addRoundedRect(in: roundeedRect, cornerSize: .init(width: roundedCorner, height: roundedCorner))
        }
    }
}

struct ToggleRingShape: Shape {

    func path(in rect: CGRect) -> Path {
        Path { path in
            let roundedCorner: CGFloat = rect.height / 2
            let roundeedRect = CGRect(x: 0, y: 0, width: rect.width, height: rect.height)
            path.addRoundedRect(in: roundeedRect, cornerSize: .init(width: roundedCorner, height: roundedCorner))
        }
    }
}

public struct MyToggleStyle: ToggleStyle {
    public init() {}
    public func makeBody(configuration: Self.Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            HStack {
                configuration.label
                    .foregroundStyle(Color.App.textPrimary)
                    .font(.fSubheadline)
                    .animation(.easeInOut(duration: 0.2), value: configuration.isOn)
                    .padding([.top, .bottom], 16)
                Spacer()
                ZStack(alignment: configuration.isOn ? .trailing : .leading) {
                    ToggleShape()
                        .fill(configuration.isOn ? Color.App.accent : Color.App.textSecondary)
                        .frame(height: 22)
                    ToggleRingShape()
                        .stroke(configuration.isOn ? Color.App.accent : Color.App.textSecondary, style: .init(lineWidth: 6))
                        .frame(width: 28, height: 28)
                        .background(Color.App.bgPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 28 / 2))
                }
                .frame(width: 48, height: 28)
                .shadow(radius: 5)
            }
        }
        .animation(.interpolatingSpring(mass: 0.1, stiffness: 1, damping: 0.4, initialVelocity: 1).speed(5), value: configuration.isOn)
        .tint(.primary)
        .buttonStyle(.borderless)
    }
}

struct MyToggleStyle_Previews: PreviewProvider {
    static var previews: some View {
        Toggle("TEST", isOn: .constant(false))
            .toggleStyle(MyToggleStyle())
    }
}
