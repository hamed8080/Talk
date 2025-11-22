//
//  ResetOrUndoStack.swift
//  ImageEditor
//
//  Created by Hamed Hosseini on 11/6/25.
//

import UIKit

class ResetOrUndoStack: UIStackView {
    var onUndo: (() -> Void)?
    var onReset: (() -> Void)?
    private let btnReset = CircularSymbolButton(ImageEditorView.resetIconName)
    private let btnUndo = CircularSymbolButton("arrow.uturn.backward")
    
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
        
        btnUndo.translatesAutoresizingMaskIntoConstraints = false
        btnUndo.onTap = { [weak self] in
            self?.onUndo?()
        }
        
        addArrangedSubview(btnReset)
        addArrangedSubview(btnUndo)
    }
}
