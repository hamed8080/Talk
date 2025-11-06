//
//  MainButtonsStack.swift
//  ImageEditor
//
//  Created by Hamed Hosseini on 11/6/25.
//

import UIKit

@MainActor
protocol MainButtonsDelegate: AnyObject {
    func addTextTapped()
    func cropTapped()
    func drawTapped()
    func flipTapped()
    func rotateTapped()
    func doneTapped()
}

class MainButtonsStack: UIStackView {
    private let btnDraw = CircularSymbolButton("pencil.and.outline", width: 32, height: 32, radius: 0, addBGEffect: false)
    private let btnAddText = CircularSymbolButton("t.square", width: 32, height: 32, radius: 0, addBGEffect: false)
    private let btnFlip = CircularSymbolButton(ImageEditorView.flipIconName, width: 32, height: 32, radius: 0, addBGEffect: false)
    private let btnRotate = CircularSymbolButton("rotate.left", width: 32, height: 32, radius: 0, addBGEffect: false)
    private let btnCrop = CircularSymbolButton("crop", width: 32, height: 32, radius: 0, addBGEffect: false)
    private let btnDone = UIButton(type: .system)
    
    private let font: UIFont
    private let doneTitle: String
   
    weak var delegate: MainButtonsDelegate?
    
    init(font: UIFont, dontTitle: String) {
        self.font = font
        self.doneTitle = dontTitle
        super.init(frame: .zero)
        setupView()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        /// Setup buttonsHStack
        let blurEffect = UIBlurEffect(style: .systemMaterialDark)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.translatesAutoresizingMaskIntoConstraints = false
        blurView.layer.cornerRadius = 12
        blurView.clipsToBounds = true
        axis = .horizontal
        spacing = 0
        distribution = .fillEqually
        alignment = .center
        translatesAutoresizingMaskIntoConstraints = false
        layer.cornerRadius = 12
        clipsToBounds = true
        layoutMargins = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
        isLayoutMarginsRelativeArrangement = true
        addSubview(blurView)
        semanticContentAttribute = .forceLeftToRight
        
        let dividerContainer = UIView()
        dividerContainer.translatesAutoresizingMaskIntoConstraints = false
        let divider = UIView()
        divider.translatesAutoresizingMaskIntoConstraints = false
        divider.backgroundColor = .white.withAlphaComponent(0.4)
        dividerContainer.addSubview(divider)
        
        /// Setup btnAddText
        btnAddText.onTap = { [weak self] in self?.delegate?.addTextTapped() }
        
        /// Setup btnFlip
        btnFlip.onTap = { [weak self] in self?.delegate?.flipTapped() }
        
        /// Setup btnRotate
        btnRotate.onTap = { [weak self] in self?.delegate?.rotateTapped() }
        
        /// Setup btnCrop
        btnCrop.onTap = { [weak self] in self?.delegate?.cropTapped() }
        
        /// Setup btnDraw
        btnDraw.onTap = { [weak self] in self?.delegate?.drawTapped() }
        
        /// Setup btnDone
        btnDone.addTarget(self, action: #selector(onDoneTapped), for: .touchUpInside)
        btnDone.setTitle(doneTitle, for: .normal)
        btnDone.setTitleColor(.white, for: .normal)
        btnDone.titleLabel?.font = font

        addArrangedSubview(btnDone)
        addArrangedSubview(dividerContainer)
        addArrangedSubview(btnDraw)
        addArrangedSubview(btnAddText)
        addArrangedSubview(btnFlip)
        addArrangedSubview(btnRotate)
        addArrangedSubview(btnCrop)
        
        NSLayoutConstraint.activate([
            dividerContainer.heightAnchor.constraint(equalToConstant: 32),
            divider.widthAnchor.constraint(equalToConstant: 1),
            divider.topAnchor.constraint(equalTo: dividerContainer.topAnchor, constant: 6),
            divider.bottomAnchor.constraint(equalTo: dividerContainer.bottomAnchor, constant: -6),
            divider.centerXAnchor.constraint(equalTo: dividerContainer.centerXAnchor),
            
            blurView.topAnchor.constraint(equalTo: topAnchor),
            blurView.bottomAnchor.constraint(equalTo: bottomAnchor),
            blurView.leadingAnchor.constraint(equalTo: leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
    }
    
    @objc private func onDoneTapped() {
        delegate?.doneTapped()
    }
}
