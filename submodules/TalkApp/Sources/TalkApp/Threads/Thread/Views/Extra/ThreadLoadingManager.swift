//
//  ThreadLoadingManager.swift
//  Talk
//
//  Created by Hamed Hosseini on 3/15/25.
//

import UIKit
import TalkUI
import Lottie
import SwiftUI

@MainActor
public class ThreadLoadingManager {
    /// Views
    private weak var parent: UIView?
    public weak var tableView: UITableView?
    private let topLoadingContainer = UIView(frame: .init(x: 0, y: 0, width: loadingViewWidth, height: loadingViewWidth + 2))
    private let bottomLoadingContainer = UIView(frame: .init(x: 0, y: 0, width: loadingViewWidth, height: loadingViewWidth + 2))
    private var topLoading: LottieAnimationView?
    private var centerLoading: LottieAnimationView?
    private var bottomLoading: LottieAnimationView?
    
    /// Models
    private static let loadingViewWidth: CGFloat = 52
    
    public func configureLoadings(parent: UIView, tableView: UITableView) {
        self.parent = parent
        self.tableView = tableView
        
        configureTopLoading()
        configureCenterLoading()
        configureBottomLoading()
        setConstraints()
    }
    
    private func configureTopLoading() {
        let topLoading = LottieAnimationView(fileName: "dots_loading.json", color: Color.App.textPrimaryUIColor ?? .black)
        self.topLoading = topLoading
        topLoading.translatesAutoresizingMaskIntoConstraints = false
        topLoading.accessibilityIdentifier = "topLoadingThreadViewController"
        topLoading.isHidden = true
        topLoadingContainer.accessibilityIdentifier = "topLoadingContainerThreadLoadingManager"
        topLoadingContainer.addSubview(topLoading)
        tableView?.tableHeaderView = topLoadingContainer
    }
    
    private func configureCenterLoading() {
        let centerLoading = LottieAnimationView(fileName: "talk_logo_animation.json")
        self.centerLoading = centerLoading
        centerLoading.translatesAutoresizingMaskIntoConstraints = false
        centerLoading.accessibilityIdentifier = "centerLoadingThreadViewController"
    }
    
    private func configureBottomLoading() {
        let bottomLoading = LottieAnimationView(fileName: "dots_loading.json", color: Color.App.textPrimaryUIColor ?? .black)
        self.bottomLoading = bottomLoading
        bottomLoading.translatesAutoresizingMaskIntoConstraints = false
        bottomLoading.accessibilityIdentifier = "bottomLoadingThreadViewController"
        bottomLoading.isHidden = true
        bottomLoadingContainer.accessibilityIdentifier = "bottomLoadingContainerThreadLoadingManager"
        bottomLoadingContainer.addSubview(bottomLoading)
        tableView?.tableFooterView = bottomLoadingContainer
    }
    
    private func setConstraints() {
        guard let topLoading = topLoading, let bottomLoading = bottomLoading else { return }
        NSLayoutConstraint.activate([
            topLoading.centerYAnchor.constraint(equalTo: topLoadingContainer.centerYAnchor),
            topLoading.centerXAnchor.constraint(equalTo: topLoadingContainer.centerXAnchor),
            topLoading.widthAnchor.constraint(equalToConstant: ThreadLoadingManager.loadingViewWidth),
            topLoading.heightAnchor.constraint(equalToConstant: ThreadLoadingManager.loadingViewWidth),

            bottomLoading.centerYAnchor.constraint(equalTo: bottomLoadingContainer.centerYAnchor),
            bottomLoading.centerXAnchor.constraint(equalTo: bottomLoadingContainer.centerXAnchor),
            bottomLoading.widthAnchor.constraint(equalToConstant: ThreadLoadingManager.loadingViewWidth),
            bottomLoading.heightAnchor.constraint(equalToConstant: ThreadLoadingManager.loadingViewWidth)
        ])
    }

    private func attachCenterLoading() {
        guard let parent = parent, let centerLoading = centerLoading else { return }
        let width: CGFloat = ThreadLoadingManager.loadingViewWidth
        centerLoading.alpha = 1.0
        parent.addSubview(centerLoading)
        centerLoading.centerYAnchor.constraint(equalTo: parent.centerYAnchor).isActive = true
        centerLoading.centerXAnchor.constraint(equalTo: parent.centerXAnchor).isActive = true
        centerLoading.widthAnchor.constraint(equalToConstant: width).isActive = true
        centerLoading.heightAnchor.constraint(equalToConstant: width).isActive = true
    }
    
    func startTopAnimation(_ animate: Bool) {
        tableView?.tableHeaderView?.isHidden = !animate
        UIView.animate(withDuration: 0.10) {
            self.tableView?.tableHeaderView?.layoutIfNeeded()
        }
        
        resizeLoadingContainerHeight(animate: animate, container: topLoadingContainer, loadingView: topLoading)
    }
    
    func startCenterAnimation(_ animate: Bool) {
        centerLoading?.isHidden = !animate
        if animate {
            attachCenterLoading()
            centerLoading?.play()
        } else {
            centerLoading?.stop()
            centerLoading?.removeFromSuperViewWithAnimation()
        }
    }

    func startBottomAnimation(_ animate: Bool) {
        tableView?.tableFooterView?.isHidden = !animate
        UIView.animate(withDuration: 0.10) {
            self.tableView?.tableFooterView?.layoutIfNeeded()
        }
        resizeLoadingContainerHeight(animate: animate, container: bottomLoadingContainer, loadingView: bottomLoading)
    }
    
    private func resizeLoadingContainerHeight(animate: Bool, container: UIView, loadingView: LottieAnimationView?) {
        loadingView?.isHidden = !animate
        container.frame.size.height = animate ? ThreadLoadingManager.loadingViewWidth + 2 : 0
        if animate {
            loadingView?.play()
        } else {
            loadingView?.stop()
        }
    }
    
    public func getBottomLoadingContainer() -> UIView {
        return bottomLoadingContainer
    }
    
    func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        topLoadingContainer.subviews.forEach { loadingView in
            loadingView.removeFromSuperview()
        }
        
        centerLoading?.removeFromSuperview()
        
        bottomLoadingContainer.subviews.forEach { loadingView in
            loadingView.removeFromSuperview()
        }
        configureTopLoading()
        configureCenterLoading()
        configureBottomLoading()
        
        setConstraints()
    }
}
