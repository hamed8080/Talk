//
//  DimView.swift
//  Talk
//
//  Created by hamed on 6/8/24.
//

import Foundation
import UIKit
import TalkViewModels
import SwiftUI

class DimView: UIView {
    public weak var viewModel: ThreadViewModel?
    private let tapGesture = UITapGestureRecognizer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureView() {
        setIsHidden(true)
        backgroundColor = Color.App.bgChatUserDarkUIColor?.withAlphaComponent(0.3)
        tapGesture.isEnabled = false
        tapGesture.addTarget(self, action: #selector(onTap))
        addGestureRecognizer(tapGesture)
    }

    public func show(_ show: Bool) {
        UIView.animate(withDuration: 0.2) {
            self.alpha = show ? 1.0 : 0.0
            self.isUserInteractionEnabled = show
            self.tapGesture.isEnabled = show
            self.setIsHidden(!show)
        } completion: { completed in
            if completed, !show {
                self.removeFromSuperview()
            }
        }
    }

    @objc private func onTap() {
        viewModel?.sendContainerViewModel.mode = .init(type: .voice)
    }
}
