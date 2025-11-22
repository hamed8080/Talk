//
//  DoneOrCancelStack.swift
//  ImageEditor
//
//  Created by Hamed Hosseini on 11/6/25.
//

import UIKit

class DoneOrCancelStack: UIStackView {
    private let doneTitle: String
    private let cancelTitle: String
    private let font: UIFont
    var onDone: (() -> Void)?
    var onCancel: (() -> Void)?
    
    init(font: UIFont, doneTitle: String, cancelTitle: String) {
        self.doneTitle = doneTitle
        self.cancelTitle = cancelTitle
        self.font = font
        super.init(frame: .zero)
        setupView()
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        translatesAutoresizingMaskIntoConstraints = false
        axis = .horizontal
        spacing = 4
        alignment = .center
        distribution = .fill
        layer.backgroundColor = UIColor(red: 48.0 / 255.0, green: 48.0 / 255.0, blue: 48.0 / 255.0, alpha: 1).cgColor
        layer.cornerRadius = 8
        layer.masksToBounds = true
        layoutMargins = .init(top: 4, left: 4, bottom: 4, right: 4)
        isLayoutMarginsRelativeArrangement = true
        
        let btnDoneDrawing = UIButton(type: .system)
        btnDoneDrawing.translatesAutoresizingMaskIntoConstraints = false
        btnDoneDrawing.setTitleColor(.white, for: .normal)
        btnDoneDrawing.backgroundColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.1)
        btnDoneDrawing.layer.cornerRadius = 8
        btnDoneDrawing.layer.masksToBounds = true
        btnDoneDrawing.addTarget(self, action: #selector(onDoneTapped), for: .touchUpInside)
        btnDoneDrawing.setTitle(doneTitle, for: .normal)
        btnDoneDrawing.titleLabel?.font = font
        
        let btnCancelDrawing = UIButton(type: .system)
        btnCancelDrawing.translatesAutoresizingMaskIntoConstraints = false
        btnCancelDrawing.setTitleColor(.white, for: .normal)
        btnCancelDrawing.backgroundColor = .clear
        btnCancelDrawing.layer.cornerRadius = 8
        btnCancelDrawing.layer.masksToBounds = true
        btnCancelDrawing.layer.borderColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.1).cgColor
        btnCancelDrawing.layer.borderWidth = 1
        btnCancelDrawing.addTarget(self, action: #selector(onCancelTapped), for: .touchUpInside)
        btnCancelDrawing.setTitle(cancelTitle, for: .normal)
        btnCancelDrawing.titleLabel?.font = font
        
        addArrangedSubview(btnDoneDrawing)
        addArrangedSubview(btnCancelDrawing)
        
        NSLayoutConstraint.activate([
            btnDoneDrawing.widthAnchor.constraint(greaterThanOrEqualToConstant: 64),
            btnDoneDrawing.heightAnchor.constraint(equalToConstant: 38),
            
            btnCancelDrawing.widthAnchor.constraint(greaterThanOrEqualToConstant: 64),
            btnCancelDrawing.heightAnchor.constraint(equalToConstant: 38),
        ])
    }
    
    @objc private func onDoneTapped() {
        onDone?()
    }
    
    @objc private func onCancelTapped() {
        onCancel?()
    }
}
