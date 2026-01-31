//
//  TabLoadingManager.swift
//  TalkApp
//
//  Created by Hamed Hosseini on 12/25/25.
//

import UIKit
import SwiftUI
import Lottie

@MainActor
class TabLoadingManager {
    private var bottomLoading: LottieAnimationView?
    private let bottomLoadingContainer: UIView
    private static let loadingViewWidth: CGFloat = 52
    private weak var tableView: UITableView?
    
    init() {
        let width = TabLoadingManager.loadingViewWidth
        let size = CGSize(width: width, height: width + 2)
        bottomLoadingContainer = UIView(frame: .init(origin: .zero, size: size))
    }
    
    func configureBottomLoading(_ tableView: UITableView) {
        self.tableView = tableView
        
        let bottomLoading = LottieAnimationView(fileName: "dots_loading.json", color: Color.App.textPrimaryUIColor ?? .black)
        bottomLoading.translatesAutoresizingMaskIntoConstraints = false
        bottomLoading.accessibilityIdentifier = "bottomLoadingThreadViewController"
        bottomLoading.isHidden = true
        self.bottomLoading = bottomLoading
        
        bottomLoadingContainer.accessibilityIdentifier = "bottomLoadingContainerThreadLoadingManager"
        bottomLoadingContainer.addSubview(bottomLoading)
        
        tableView.tableFooterView = bottomLoadingContainer
        
        NSLayoutConstraint.activate([
            bottomLoading.centerYAnchor.constraint(equalTo: bottomLoadingContainer.centerYAnchor),
            bottomLoading.centerXAnchor.constraint(equalTo: bottomLoadingContainer.centerXAnchor),
            bottomLoading.widthAnchor.constraint(equalToConstant: TabLoadingManager.loadingViewWidth),
            bottomLoading.heightAnchor.constraint(equalToConstant: TabLoadingManager.loadingViewWidth)
        ])
        
        bottomLoadingContainer.frame.size.height = TabLoadingManager.loadingViewWidth + 2
    }
    
    func startBottomAnimation(_ animate: Bool) {
        self.tableView?.tableFooterView = animate ? bottomLoadingContainer : nil
        bottomLoading?.isHidden = !animate
        if animate {
            bottomLoading?.play()
        } else {
            bottomLoading?.stop()
        }
        UIView.animate(withDuration: 0.25) {
            self.tableView?.tableFooterView?.layoutIfNeeded()
        }
    }
}
