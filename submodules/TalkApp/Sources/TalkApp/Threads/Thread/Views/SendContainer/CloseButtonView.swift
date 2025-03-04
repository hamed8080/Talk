//
//  CloseButtonView.swift
//  Talk
//
//  Created by hamed on 11/3/23.
//

import SwiftUI
import TalkUI
import UIKit

public final class CloseButtonView: UIButton {
    public var action: (() -> Void)?

    public init() {
        super.init(frame: .zero)
        configureView()
    }

    public required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureView() {
        let image = UIImage(systemName: "xmark")
        setImage(image, for: .normal)
        imageView?.contentMode = .scaleAspectFit
        tintColor = Color.App.iconSecondaryUIColor
        addTarget(self, action: #selector(onUnpinMessageTapped), for: .touchUpInside)
//
//        NSLayoutConstraint.activate([
//            widthAnchor.constraint(equalToConstant: 36),
//            heightAnchor.constraint(equalToConstant: 36),
//        ])
    }

    @objc private func onUnpinMessageTapped(_ sender: UIButton) {
        action?()
    }
}

struct CloseButtonView_Previews: PreviewProvider {
    struct CloseButtonViewWrapper: UIViewRepresentable {
        func makeUIView(context: Context) -> some UIView { CloseButtonView() }
        func updateUIView(_ uiView: UIViewType, context: Context) {}
    }

    static var previews: some View {
        CloseButtonViewWrapper()
    }
}
