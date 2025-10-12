//
//  PrimaryTabBarViewController.swift
//  UIKitNavigation
//
//  Created by Hamed Hosseini on 10/12/25.
//

import UIKit
import TalkUI
import SwiftUI

/// Apple won't allow to put a UITabBarViewController as a primary view controller in a UISplitViewController
/// So we have to make it ourself.
class PrimaryTabBarViewController: UIViewController {
    private var active: UIViewController?
    private var tabBar = UITabBar()
    private let container = UIView()
    private let contactsVC = ContactTableViewController(viewModel: AppState.shared.objectsContainer.contactsVM)
    private let chatsVC = ThreadsTableViewController(viewModel: AppState.shared.objectsContainer.threadsVM)
    private let settingsVC = UIHostingController(rootView: SettingsTabWrapper())
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.setNavigationBarHidden(true, animated: false)
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
        
        tabBar.items = tabs
        tabBar.delegate = self
        
        view.addSubview(container)
        view.addSubview(tabBar)
        container.translatesAutoresizingMaskIntoConstraints = false
        tabBar.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            tabBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 0),
            tabBar.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            tabBar.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            tabBar.heightAnchor.constraint(equalToConstant: 52),
            
            container.topAnchor.constraint(equalTo: view.topAnchor, constant: 0),
            container.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            container.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        switchTo(chatsVC)
        tabBar.selectedItem = chatsTab
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
        vc.view.frame.size.width = splitViewController?.isCollapsed == true ? container.bounds.width : splitViewController?.maximumPrimaryColumnWidth ?? 0
        vc.view.frame.size.height = container.bounds.height - (tabBar.frame.height + view.safeAreaInsets.bottom)
        vc.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        container.addSubview(vc.view)
        vc.didMove(toParent: self)
        active = vc
    }
    
    /// It is needed for the first tab.
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        active?.view.frame.size.width = splitViewController?.isCollapsed == true ? container.bounds.width : splitViewController?.maximumPrimaryColumnWidth ?? 0
        active?.view.frame.size.height = container.bounds.height
    }
    
    private func makeTabItem(image: String, title: String) -> UITabBarItem {
        let fontAttr = [
            NSAttributedString.Key.font: UIFont.fBody
        ]
        
        let tabItem = UITabBarItem(title: title.bundleLocalized(), image: UIImage(systemName: image), selectedImage: nil)
        tabItem.setTitleTextAttributes(fontAttr, for: .normal)
        tabItem.setTitleTextAttributes(fontAttr, for: .selected)
        
        return tabItem
    }
}

extension PrimaryTabBarViewController: UITabBarDelegate {
    func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        changeTab()
    }
}
