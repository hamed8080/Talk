//
//  ChatsViewController.swift
//  UIKitNavigation
//
//  Created by Hamed Hosseini on 10/12/25.
//

import UIKit

class ChatsViewController: UITableViewController {
    
    var items = ["Hello", "Bye", "How are you?"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("Chats view appeared")
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = items[indexPath.row]
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let vc = NewThreadViewController()
        vc.conversation = items[indexPath.row]
        
        // Check if container is iPhone navigation controller or iPad split view container or on iPadOS we are in a narrow window
        if splitViewController?.isCollapsed == true {
            // iPhone — push onto the existing navigation stack
            navigationController?.pushViewController(vc, animated: true)
        } else {
            let secondaryVC = splitViewController?.viewController(for: .secondary) as? FastNavigationController
            let threadVC = secondaryVC?.viewControllers.last as? NewThreadViewController
            
            if let threadVC = threadVC, threadVC.conversation == items[indexPath.row] {
                // Do nothing if the user tapped on the same conversation on iPadOS row.
            } else {
                // iPad — show in secondary column
                let nav = FastNavigationController(rootViewController: vc)
                showDetailViewController(nav, sender: nil)
            }
        }
    }
}
