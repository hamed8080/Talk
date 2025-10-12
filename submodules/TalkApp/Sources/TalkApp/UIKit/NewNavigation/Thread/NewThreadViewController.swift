//
//  NewThreadViewController.swift
//  UIKitNavigation
//
//  Created by Hamed Hosseini on 10/12/25.
//

import UIKit

class NewThreadViewController: UIViewController {
    var conversation: String?
    private let label = UILabel()
    private let popButton = UIButton(type: .system)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .purple
        
        label.text = conversation
        label.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(navigateToDetailView))
        label.addGestureRecognizer(tapGesture)
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        
        popButton.setTitle("Pop", for: .normal)
        popButton.setTitleColor(.blue, for: .normal)
        popButton.addTarget(self, action: #selector(onPopTapped), for: .touchUpInside)
        popButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(popButton)
        
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            popButton.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 8),
            popButton.centerXAnchor.constraint(equalTo: label.centerXAnchor),
        ])
    }
    
    @objc private func navigateToDetailView() {
        let vc = NewDetailViewController()
        vc.conversation = conversation
        
        /// In the ThreadViewController we only push forward and not using setDetailViewController
        /// because we are inside a navigation controller on both iPad and iPhone.
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc private func onPopTapped() {
        
        /// Deselect row on iPadOS
        let primaryVC = splitViewController?.viewController(for: .primary) as? FastNavigationController
        let tabVC = primaryVC?.viewControllers.first as? PrimaryTabBarViewController
        let chatsVC = tabVC?.children.compactMap({ $0 as? ChatsViewController }).first
        if let selectedIndexPath = chatsVC?.tableView.indexPathForSelectedRow {
            chatsVC?.tableView.deselectRow(at: selectedIndexPath, animated: true)
        }
        
        // iPhone (collapsed)
        // on iPhone PrimaryTabBarViewController is the root view controller of the navigation stack,
        // and thread view controller is the second view controller of the navigation stack,
        // So as long as we are in thread view controller, the number of view controllers inside the stack is greater than 1.
        if let nav = navigationController, nav.viewControllers.count > 1 {
            nav.popViewController(animated: true)
        }
        // iPad (side-by-side)
        else if let splitVC = splitViewController {
            splitVC.setViewController(nil, for: .secondary)
        }
    }
    
    deinit {
        print("[DEINIT] ThreadViewController")
    }
}
