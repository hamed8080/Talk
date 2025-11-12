//
//  ThreadLoadingManager.swift
//  Talk
//
//  Created by Hamed Hosseini on 3/15/25.
//

import UIKit
import TalkUI
import Lottie

@MainActor
public class ThreadLoadingManager {
    /// Views
    private weak var parent: UIView?
    public weak var tableView: UITableView?
    private let topLoadingContainer = UIView(frame: .init(x: 0, y: 0, width: loadingViewWidth, height: loadingViewWidth + 2))
    private let bottomLoadingContainer = UIView(frame: .init(x: 0, y: 0, width: loadingViewWidth, height: loadingViewWidth + 2))
    private var topLoading = LottieAnimationView(talkName: "talk_logo_animation.json")
    private var centerLoading = LottieAnimationView(talkName: "talk_logo_animation.json")
    private var bottomLoading = LottieAnimationView(talkName: "talk_logo_animation.json")
    
    /// Models
    private static let loadingViewWidth: CGFloat = 52
    
    public func configureLoadings(parent: UIView, tableView: UITableView) {
        self.parent = parent
        self.tableView = tableView
        
        topLoading.translatesAutoresizingMaskIntoConstraints = false
        topLoading.accessibilityIdentifier = "topLoadingThreadViewController"
        topLoading.isHidden = true
        topLoadingContainer.addSubview(topLoading)
        tableView.tableHeaderView = topLoadingContainer

        centerLoading.translatesAutoresizingMaskIntoConstraints = false
        centerLoading.accessibilityIdentifier = "centerLoadingThreadViewController"

        bottomLoading.translatesAutoresizingMaskIntoConstraints = false
        bottomLoading.accessibilityIdentifier = "bottomLoadingThreadViewController"
        bottomLoading.isHidden = true
        bottomLoadingContainer.addSubview(self.bottomLoading)
        tableView.tableFooterView = bottomLoadingContainer

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
        guard let parent = parent else { return }
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
        UIView.animate(withDuration: 0.25) {
            self.tableView?.tableHeaderView?.layoutIfNeeded()
        }
        
        topLoading.isHidden = !animate
        if animate {
            topLoading.play()
        } else {
            topLoading.stop()
        }
    }
    
    func startCenterAnimation(_ animate: Bool) {
        centerLoading.isHidden = !animate
        if animate {
            attachCenterLoading()
            centerLoading.play()
        } else {
            centerLoading.stop()
            centerLoading.removeFromSuperViewWithAnimation()
        }
    }

    func startBottomAnimation(_ animate: Bool) {
        bottomLoading.isHidden = !animate
        if animate {
            bottomLoading.play()
        } else {
            bottomLoading.stop()
        }
    }
    
    public func getBottomLoadingContainer() -> UIView{
        return bottomLoadingContainer
    }
}
