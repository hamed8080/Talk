//
//  NewDetailViewController.swift
//  UIKitNavigation
//
//  Created by Hamed Hosseini on 10/12/25.
//

import UIKit

class NewDetailViewController: UIViewController {
    var conversation: String?
    private let label = UILabel()
    private let popButton = UIButton(type: .system)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .cyan
        
        label.text = "Detail-\(conversation ?? "")"
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        
        popButton.setTitle("Pop Detail", for: .normal)
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
    
    @objc private func onPopTapped() {
        // iPhone (collapsed)
        if let nav = navigationController, nav.viewControllers.count > 1 {
            nav.popViewController(animated: true)
        }
        // iPad (side-by-side)
        else if let splitVC = splitViewController {
            splitVC.setViewController(nil, for: .secondary)
        }
    }
    
    deinit {
        print("[DEINIT] DetailViewController")
    }
}
