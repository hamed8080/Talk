//
//  PrimaryTabBarViewController.swift
//  UIKitNavigation
//
//  Created by Hamed Hosseini on 10/12/25.
//

import UIKit
import TalkUI
import SwiftUI
import Combine

/// Apple won't allow to put a UITabBarViewController as a primary view controller in a UISplitViewController
/// So we have to make it ourself.
class PrimaryTabBarViewController: UIViewController {
    private var active: UIViewController?
    private var tabBar = UITabBar()
    private let container = UIView()
    private let contactsVC = ContactTableViewController(viewModel: AppState.shared.objectsContainer.contactsVM)
    private let chatsVC = ThreadsTableViewController(viewModel: AppState.shared.objectsContainer.threadsVM)
    private let settingsVC = UIHostingController(rootView: SettingsTabWrapper())
    private var windowModeCancellable: AnyCancellable?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.semanticContentAttribute = Language.isRTL ? .forceRightToLeft : .forceLeftToRight
        
        let contactsTab = makeTabItem(image: "person.crop.circle", title: "Tab.contacts")
        contactsTab.tag = 0
        
        let chatsTab = makeTabItem(image: "ellipsis.message.fill", title: "Tab.chats")
        chatsTab.tag = 1
        
        let settingsTab = makeTabItem(image: "gear", title: "Tab.settings")
        settingsTab.tag = 2
        
        /// Listen to image profile.
        AppState.shared.objectsContainer.userProfileImageVM.onImage = { @Sendable [weak self] newImage in
            Task { @MainActor in
                if AppState.shared.objectsContainer.userProfileImageVM.isImageReady {
                    let roundedImage = UIImage.tabbarRoundedImage(image: newImage)?.withRenderingMode(.alwaysOriginal)
                    settingsTab.image = roundedImage
                    settingsTab.imageInsets = UIEdgeInsets(top: 4, left: 0, bottom: -4, right: 0)
                }
            }
        }
        
        let tabs: [UITabBarItem] = [contactsTab, chatsTab, settingsTab]
        
        tabBar.translatesAutoresizingMaskIntoConstraints = false
        tabBar.items = tabs
        tabBar.delegate = self
        tabBar.accessibilityIdentifier = "tabBarPrimaryTabBarViewController"
        
        container.translatesAutoresizingMaskIntoConstraints = false
        container.accessibilityIdentifier = "containerPrimaryTabBarViewController"
        
        // Prevent click on the bottom part of the tabbar
        let touchBlockerView = UIView()
        touchBlockerView.translatesAutoresizingMaskIntoConstraints = false
        touchBlockerView.backgroundColor = .clear
        touchBlockerView.isUserInteractionEnabled = true
        view.addSubview(touchBlockerView)
        
        view.addSubview(container)
        view.addSubview(tabBar)
        view.bringSubviewToFront(touchBlockerView)
        view.bringSubviewToFront(tabBar)

        NSLayoutConstraint.activate([
            touchBlockerView.leadingAnchor.constraint(equalTo: tabBar.leadingAnchor),
            touchBlockerView.trailingAnchor.constraint(equalTo: tabBar.trailingAnchor),
            touchBlockerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            touchBlockerView.topAnchor.constraint(equalTo: tabBar.topAnchor),
            
            tabBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 0),
            tabBar.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            tabBar.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            tabBar.heightAnchor.constraint(equalToConstant: ConstantSizes.bottomToolbarSize),
            
            container.topAnchor.constraint(equalTo: view.topAnchor, constant: 0),
            container.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            container.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        switchTo(chatsVC)
        tabBar.selectedItem = chatsTab
        registerWindowChange()
    }
    
    @objc private func changeTab() {
        switch tabBar.selectedItem?.tag {
        case 0: switchTo(contactsVC)
        case 1: switchTo(chatsVC)
        case 2: switchTo(settingsVC)
        default:
            break
        }
    }
    
    private func switchTo(_ vc: UIViewController) {
        if let active = active {
            active.willMove(toParent: nil)
            active.view.removeFromSuperview()
            active.removeFromParent()
        }
        
        addChild(vc)
        vc.view.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(vc.view)
        vc.didMove(toParent: self)
        active = vc
        NSLayoutConstraint.activate([
            vc.view.topAnchor.constraint(equalTo: container.topAnchor),
            vc.view.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])
        
        if Language.isRTL {
            vc.view.leadingAnchor.constraint(equalTo: container.leadingAnchor).isActive = true
        } else {
            vc.view.trailingAnchor.constraint(equalTo: container.trailingAnchor).isActive = true
        }
        
        if splitViewController?.isCollapsed == true {
            vc.view.widthAnchor.constraint(equalTo: container.widthAnchor).isActive = true
        } else {
            vc.view.widthAnchor.constraint(equalToConstant: splitViewController?.maximumPrimaryColumnWidth ?? 0).isActive = true
        }
    }
    
    private func makeTabItem(image: String, title: String) -> UITabBarItem {
        let fontAttr = [
            NSAttributedString.Key.font: UIFont.normal(.body)
        ]
        
        let tabItem = UITabBarItem(title: title.bundleLocalized(), image: UIImage(systemName: image), selectedImage: nil)
        tabItem.setTitleTextAttributes(fontAttr, for: .normal)
        tabItem.setTitleTextAttributes(fontAttr, for: .selected)
        
        return tabItem
    }
    
    private func registerWindowChange() {
        windowModeCancellable = NotificationCenter.windowMode.publisher(for: .windowMode).sink { [weak self] newValue in
            guard let self = self else { return }
            if let windowMode = newValue.object as?  WindowMode {
                /// Remove active width constraint
                let constraint = active?.view.constraints.first(where: { $0.firstAttribute == .width })
                if let constraint = constraint {
                    active?.view.removeConstraint(constraint)
                }
                
                /// Add a new width constriant again.
                if splitViewController?.isCollapsed == true {
                    active?.view.widthAnchor.constraint(equalTo: container.widthAnchor).isActive = true
                } else {
                    let width: CGFloat = windowMode == .ipadFullScreen ? 420 : 320
                    splitViewController?.preferredPrimaryColumnWidth = width
                    active?.view.widthAnchor.constraint(equalToConstant: width).isActive = true
                }
            }
        }
    }
}

extension PrimaryTabBarViewController: UITabBarDelegate {
    func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        changeTab()
    }
}
