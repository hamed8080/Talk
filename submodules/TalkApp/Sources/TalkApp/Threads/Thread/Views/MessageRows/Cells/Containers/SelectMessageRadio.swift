//
//  SelectMessageRadio.swift
//  Talk
//
//  Created by hamed on 3/12/24.
//

import Foundation
import UIKit
import TalkViewModels
import SwiftUI

public final class SelectMessageRadio: UIView {
    private let imageView = UIImageView()

    private static let staticUNSelectedImage: UIImage? = .init(systemName: "circle",
                                                             withConfiguration: UIImage.SymbolConfiguration(paletteColors: [UIColor.gray,
                                                                                                                            UIColor.clear]))
    private static let staticSelectedImage: UIImage? = .init(systemName: "checkmark.circle.fill",
                                                            withConfiguration: UIImage.SymbolConfiguration(paletteColors: [Color.App.whiteUIColor!,
                                                                                                                           Color.App.accentUIColor!]))
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureView() {
        translatesAutoresizingMaskIntoConstraints = false
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.image = SelectMessageRadio.staticUNSelectedImage
        imageView.accessibilityIdentifier = "imageViewSelectMessageRadio"
        addSubview(imageView)

        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: ConstantSizes.selectMessageRadioWidth),
            heightAnchor.constraint(equalToConstant: ConstantSizes.selectMessageRadioHeight),
            imageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor),
            imageView.widthAnchor.constraint(equalToConstant: ConstantSizes.selectMessageRadioImageViewWidth),
            imageView.heightAnchor.constraint(equalToConstant: ConstantSizes.selectMessageRadioImageViewHeight),
        ])
    }

    public func set(selected: Bool, viewModel: MessageRowViewModel) {
        imageView.image = selected ? SelectMessageRadio.staticSelectedImage : SelectMessageRadio.staticUNSelectedImage
    }
}
