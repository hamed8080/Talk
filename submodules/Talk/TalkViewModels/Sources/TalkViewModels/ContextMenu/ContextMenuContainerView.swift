//
//  ContextMenuContainerView.swift
//  Talk
//
//  Created by hamed on 6/28/24.
//

import Foundation
import UIKit

@MainActor
public protocol ContextMenuDelegate: AnyObject {
    func showContextMenu(_ indexPath: IndexPath?, contentView: UIView)
    func dismissContextMenu(indexPath: IndexPath?)
}

public class ContextMenuContainerView: UIView {
    private let scrollView: UIScrollView
    private var effectView: UIVisualEffectView!
    let contentView = UIView()
    var indexPath: IndexPath?
    private weak var delegate: ContextMenuDelegate?
    private var vc: UIViewController? { delegate as? UIViewController }

    public init(delegate: ContextMenuDelegate) {
        self.delegate = delegate
        let frame = (delegate as? UIViewController)?.navigationController?.view.frame ?? .zero
        self.scrollView = UIScrollView(frame: frame)
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(from:) has not been implemented")
    }

    private func setupView() {
        let blurEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)
        effectView = UIVisualEffectView(effect: blurEffect)
        effectView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(effectView)

        self.isHidden = true
        alpha = 0.0

        scrollView.backgroundColor = .clear
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scrollView)

        contentView.backgroundColor = .clear
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(hideAndCall))
        tapGesture.cancelsTouchesInView = false
        contentView.addGestureRecognizer(tapGesture)

        // Constraints for effectView
        NSLayoutConstraint.activate([
            effectView.topAnchor.constraint(equalTo: self.topAnchor),
            effectView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            effectView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            effectView.trailingAnchor.constraint(equalTo: self.trailingAnchor)
        ])
        
        // Constraints for scrollView
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: self.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: self.trailingAnchor)
        ])

        // Constraints for contentView
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 2000) // Set height to 2000
        ])
    }

    public func setContentView(_ view: UIView, indexPath: IndexPath?) {
        self.indexPath = indexPath
        changeSizeIfNeeded()
        scrollView.contentSize = .init(width: view.bounds.width, height: view.subviews.map({$0.frame.height}).reduce(0, +))
        view.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(view)
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            view.widthAnchor.constraint(equalTo: contentView.widthAnchor)
        ])
    }

    public func show() {
        self.vc?.view.addSubview(self)
        self.isHidden = false
        alpha = 0.0
        disableScrollToTopForBehindScrollViews(disable: true)
        UIView.animate(withDuration: 0.2) {
            self.alpha = 1.0
        } completion: { compelted in
            self.isHidden = false
        }
    }

    @objc private func hideAndCall() {
        hide()
        delegate?.dismissContextMenu(indexPath: indexPath)
    }

    @objc public func hide() {
        disableScrollToTopForBehindScrollViews(disable: false)
        UIView.animate(withDuration: 0.2) {
            self.alpha = 0.0
        } completion: { completed in
            if completed {
                self.isHidden = true
                self.contentView.subviews.forEach { subview in
                    subview.removeFromSuperview()
                }
                self.removeFromSuperview()
            }
        }
    }

    private func changeSizeIfNeeded() {
        frame = vc?.view.frame ?? .zero
        effectView.frame = vc?.view.frame ?? .zero
    }

    func disableScrollToTopForBehindScrollViews(disable: Bool) {
        vc?.view.subviews.compactMap({$0 as? UIScrollView}).forEach{ scrollView in
            scrollView.scrollsToTop = !disable
        }
    }
}
