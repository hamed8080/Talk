//
//  EmptyThreadView.swift
//  Talk
//
//  Created by hamed on 3/7/24.
//

import SwiftUI
import TalkViewModels
import TalkUI

public final class EmptyThreadView: UIView {

    public init() {
        super.init(frame: .zero)
        configureView()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureView() {

        let vStack = UIStackView()
        vStack.translatesAutoresizingMaskIntoConstraints = false
        vStack.axis = .vertical
        vStack.spacing = 4
        vStack.alignment = .center
        vStack.layoutMargins = .init(horizontal: 48, vertical: 48)
        vStack.isLayoutMarginsRelativeArrangement = true
        vStack.layer.masksToBounds = true
        vStack.layer.cornerRadius = 12
        vStack.accessibilityIdentifier = "vStackEmptyThreadView"

        let effect = UIBlurEffect(style: .systemUltraThinMaterial)
        let effectView = UIVisualEffectView(effect: effect)
        effectView.translatesAutoresizingMaskIntoConstraints = false
        effectView.accessibilityIdentifier = "effectViewEmptyThreadView"
        vStack.addSubview(effectView)

        let label = UILabel()
        label.textColor = Color.App.textPrimaryUIColor
        label.numberOfLines = 2
        label.textAlignment = .center
        label.font = UIFont.uiiransansSubtitle
        label.accessibilityIdentifier = "labelEmptyThreadView"

        let image = UIImageView(image: nil)
        image.translatesAutoresizingMaskIntoConstraints = false
        image.contentMode = .scaleAspectFit
        image.tintColor = Color.App.accentUIColor
        image.accessibilityIdentifier = "imageEmptyThreadView"

        vStack.addArrangedSubview(label)
        vStack.addArrangedSubview(image)

        addSubview(vStack)

        NSLayoutConstraint.activate([
            vStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            vStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            vStack.centerYAnchor.constraint(equalTo: centerYAnchor),
            effectView.leadingAnchor.constraint(equalTo: leadingAnchor),
            effectView.trailingAnchor.constraint(equalTo: trailingAnchor),
            effectView.topAnchor.constraint(equalTo: topAnchor),
            effectView.bottomAnchor.constraint(equalTo: bottomAnchor),
            image.widthAnchor.constraint(equalToConstant: 36),
            image.heightAnchor.constraint(equalToConstant: 36)
        ])
        prepareIU(image, label)
    }

    private func prepareIU(_ imageView: UIImageView, _ label: UILabel) {
        Task {
            let image = UIImage(systemName: "text.bubble")
            let text = "Thread.noMessage".localized()
            await MainActor.run {
                label.text = text
                imageView.image = image
            }
        }
    }
}

struct EmptyThreadViewWrapper: UIViewRepresentable {
    func makeUIView(context: Context) -> some UIView {
        return EmptyThreadView()
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {

    }
}
struct EmptyThreadView_Previews: PreviewProvider {
    static var previews: some View {
        EmptyThreadViewWrapper()
    }
}
