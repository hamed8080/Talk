//
//  CATextLayerView.swift
//  Talk
//
//  Created by Hamed Hosseini on 12/20/24.
//

import Foundation
import UIKit
import TalkViewModels

class CATextLayerView: UIView {
    private var hConstraint: NSLayoutConstraint!
    private var wConstrint: NSLayoutConstraint!
    private var textLayer = CATextLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureView() {
        translatesAutoresizingMaskIntoConstraints = false
        hConstraint = heightAnchor.constraint(equalToConstant: 0)
        wConstrint = widthAnchor.constraint(equalToConstant: 0)
        NSLayoutConstraint.activate([
            hConstraint,
            wConstrint,
        ])
    }

    public func set(_ viewModel: MessageRowViewModel) {
//        guard let textLayer = viewModel.calMessage.textLayer, let textRect = viewModel.calMessage.textRect else { return }
//        self.textLayer = textLayer
//        self.layer.addSublayer(self.textLayer)
//        hConstraint.constant = textRect.height
//        wConstrint.constant = textRect.width
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        textLayer.frame = bounds
    }
}
