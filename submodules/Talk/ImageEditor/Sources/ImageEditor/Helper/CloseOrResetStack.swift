//
//  CloseOrResetStack.swift
//  ImageEditor
//
//  Created by Hamed Hosseini on 11/6/25.
//

import UIKit

class CloseOrResetStack: UIStackView {
    var onReset: (() -> Void)?
    var onClose: (() -> Void)?
    private let btnClose = CircularSymbolButton("xmark")
    private let btnReset = CircularSymbolButton(ImageEditorView.resetIconName)
    
    init() {
        super.init(frame: .zero)
        setupView()
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        axis = .horizontal
        spacing = 8
        
        btnReset.translatesAutoresizingMaskIntoConstraints = false
        btnReset.onTap = { [weak self] in
            self?.onReset?()
        }
        
        btnClose.translatesAutoresizingMaskIntoConstraints = false
        btnClose.onTap = { [weak self] in
            self?.onClose?()
        }
        
        addArrangedSubview(btnReset)
        addArrangedSubview(btnClose)
    }
}
