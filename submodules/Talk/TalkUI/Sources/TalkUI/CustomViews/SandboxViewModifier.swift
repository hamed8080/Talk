//
//  SandboxViewModifier.swift
//  TalkUI
//
//  Created by Hamed Hosseini on 2/19/25.
//

import SwiftUI

struct SandboxViewModifier: ViewModifier {
    func body(content: Content) -> some View {
        content.overlay(alignment: .topTrailing) {
            HStack(alignment: .top) {
                Spacer()
                Text("SANDBOOX")
                    .font(.caption2.bold())
                    .foregroundStyle(Color.App.accent)
                    .padding(4)
                    .background(Material.ultraThick)
                    .clipShape(RoundedRectangle(cornerSize: .init(width: 4, height: 4)))
            }
            .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 4))
        }
    }
}

public class SandboxView: UILabel {
    
    public init() {
        super.init(frame: .zero)
        configureView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(from:) has not been implemented")
    }

    private func configureView() {
        text = "SANDBOOX"
        textColor = Color.App.accentUIColor
        font = UIFont.preferredFont(forTextStyle: .caption2)
    }
}

public extension View {
    func sandboxLabel() -> some View {
        modifier(SandboxViewModifier())
    }
}
