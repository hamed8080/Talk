//
//  ArchivesTableViewController.swift
//  Talk
//
//  Created by Hamed Hosseini on 9/23/21.
//

import Foundation
import UIKit
import Chat
import SwiftUI
import TalkViewModels

struct ArchivesTableViewControllerWrapper: UIViewControllerRepresentable {
    let viewModel: ThreadsViewModel
    
    func makeUIViewController(context: Context) -> some UIViewController {
        let vc = ThreadsTableViewController(viewModel: viewModel)
        if !viewModel.isArchiveObserverInitialized {
            viewModel.setupObservers()
            viewModel.isArchiveObserverInitialized = true
        }
        return vc
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) { }
}
