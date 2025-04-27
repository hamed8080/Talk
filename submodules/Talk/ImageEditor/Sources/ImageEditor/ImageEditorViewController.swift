//
//  ImageEditorViewController.swift
//  ImageEditor
//
//  Created by Hamed Hosseini on 4/27/25.
//

import UIKit
import SwiftUI

public class ImageEditorViewController: UIViewController {
    public let url: URL
    public let font: UIFont
    public let doneTitle: String
    public var onDone: ((URL?, Error?) -> Void)?
    public var onClose: (() -> Void)?
    
    public init(url: URL, font: UIFont, doneTitle: String) {
        self.url = url
        self.font = font
        self.doneTitle = doneTitle
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        guard let onDone = onDone else {
            fatalError("Please pass onDone closure")
            return
        }
        let editorView = ImageEditorView(url: url, font: font, doneTitle: doneTitle, onDone: onDone)
        editorView.onClose = onClose
        editorView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(editorView)
        NSLayoutConstraint.activate([
            editorView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            editorView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            editorView.topAnchor.constraint(equalTo: self.view.topAnchor),
            editorView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
        ])
    }
}

public struct ImageEditorWrapper: UIViewRepresentable {
    public let url: URL
    public let doneTitle: String
    public let onDone: (URL?, Error?) -> Void
    public let onClose: (() -> Void)?
    
    public init(url: URL, doneTitle: String, onDone: @escaping (URL?, Error?) -> Void, onClose: (() -> Void)?) {
        self.url = url
        self.doneTitle = doneTitle
        self.onDone = onDone
        self.onClose = onClose
    }
    
    public func makeUIView(context: Context) -> UIView {
        let view = ImageEditorView(url: url, doneTitle: doneTitle, onDone: onDone)
        view.onClose = onClose
        return view
    }
    
    public func updateUIView(_ uiView: UIViewType, context: Context) {}
    
}
