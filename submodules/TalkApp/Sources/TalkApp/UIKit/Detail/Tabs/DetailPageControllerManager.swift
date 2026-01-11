//
//  DetailPageControllerManager.swift
//  TalkApp
//
//  Created by Hamed Hosseini on 1/4/26.
//

import UIKit
import TalkViewModels

@MainActor
final class DetailPageControllerManager: UIPageViewController {
    public weak var vc: UIDetailViewController?
    public private(set) var controllers: [UIViewController] = []
    private let viewModel: ThreadDetailViewModel
    public private(set) var selectedIndex: Int = 0
    
    init(viewModel: ThreadDetailViewModel) {
        self.viewModel = viewModel
        self.controllers = []
        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func setTabControllersDelegate() {
        controllers.forEach { page in
            if let selectableVC = page as? TabControllerDelegate {
                selectableVC.scrollDelegate = self.vc
                selectableVC.onSelectDelegate = self.vc
                selectableVC.detailVM = viewModel
            }
        }
    }
    
    public func setupPageView(vc: UIDetailViewController) {
        self.vc = vc
        appendTabControllers()
        setTabControllersDelegate()
        
        view.translatesAutoresizingMaskIntoConstraints = false
        view.semanticContentAttribute = Language.isRTL ? .forceRightToLeft : .forceLeftToRight
        vc.addChild(self)
        didMove(toParent: vc)
        delegate = self
        dataSource = self
        setViewControllers([controllers[0]], direction: .forward, animated: false)
        disableAllScrollViewControllers()
    }
    
    
    public func setPage(index: Int) {
        let direction: UIPageViewController.NavigationDirection = index > selectedIndex ? .forward : .reverse
        setViewControllers([controllers[index]], direction: direction, animated: true)
        selectedIndex = index
    }
    
    public func appendTabControllers() {
        for tab in viewModel.tabs {
            switch tab.id {
            case .members:
                if let viewModel = tab.viewModel as? ParticipantsViewModel {
                    controllers.append(MembersTableViewController(viewModel: viewModel))
                }
            case .pictures:
                if let viewModel = tab.viewModel as? DetailTabDownloaderViewModel {
                    controllers.append(PicturesCollectionViewController(viewModel: viewModel))
                }
            case .video:
                if let viewModel = tab.viewModel as? DetailTabDownloaderViewModel {
                    controllers.append(VideosTableViewController(viewModel: viewModel))
                }
            case .music:
                if let viewModel = tab.viewModel as? DetailTabDownloaderViewModel {
                    controllers.append(MusicsTableViewController(viewModel: viewModel))
                }
            case .voice:
                if let viewModel = tab.viewModel as? DetailTabDownloaderViewModel {
                    controllers.append(VoicesTableViewController(viewModel: viewModel))
                }
            case .file:
                if let viewModel = tab.viewModel as? DetailTabDownloaderViewModel {
                    controllers.append(FilesTableViewController(viewModel: viewModel))
                }
            case .link:
                if let viewModel = tab.viewModel as? DetailTabDownloaderViewModel {
                    controllers.append(LinksTableViewController(viewModel: viewModel))
                }
            case .mutual:
                if let viewModel = tab.viewModel as? MutualGroupViewModel {
                    controllers.append(MutualGroupsTableViewController(viewModel: viewModel))
                }
            }
        }
    }
}

// MARK: - UIPageViewController Delegate & DataSource
extension DetailPageControllerManager: UIPageViewControllerDelegate, UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let index = controllers.firstIndex(of: viewController), index > 0 else { return nil }
        return controllers[index - 1]
    }

    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let index = controllers.firstIndex(of: viewController), index < controllers.count - 1 else { return nil }
        return controllers[index + 1]
    }

    func pageViewController(_ pageViewController: UIPageViewController,
                            didFinishAnimating finished: Bool,
                            previousViewControllers: [UIViewController],
                            transitionCompleted completed: Bool) {
        guard completed, let visibleVC = pageViewController.viewControllers?.first,
              let index = controllers.firstIndex(of: visibleVC) else { return }
        selectedIndex = index
        vc?.headerSectionView?.updateTabSelection(animated: true, selectedIndex: selectedIndex)
        setCurrentChildScrollEnabled(false)
        vc?.tableView.isScrollEnabled = true
    }
}

extension DetailPageControllerManager {
    /// Disable all controllers for UITableViews/CollectionViews initially.
    private func disableAllScrollViewControllers() {
        controllers.compactMap { $0 as? UIViewControllerScrollDelegate }.forEach {
            $0.getInternalScrollView().isScrollEnabled = false
        }
    }
    
    public func setCurrentChildScrollEnabled(_ enabled: Bool) {
        guard
            let childVC = viewControllers?.first,
            let scrollView = (childVC as? UIViewControllerScrollDelegate)?.getInternalScrollView()
        else { return }
        scrollView.isScrollEnabled = enabled
    }
    
    public func setBottomInsetForChilds(bottomInset: CGFloat) {
        controllers.compactMap { $0 as? UIViewControllerScrollDelegate }.forEach {
            $0.setBottomInset(bottomInset)
        }
    }
}
