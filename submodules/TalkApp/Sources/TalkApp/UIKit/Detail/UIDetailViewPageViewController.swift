//
//  UIDetailViewPageViewController.swift
//  TalkApp
//
//  Created by Hamed Hosseini on 11/11/25.
//

import AdditiveUI
import Chat
import SwiftUI
import TalkUI
import TalkViewModels
import TalkModels
import UIKit

fileprivate enum DetailTableViewSection: Int, CaseIterable {
    case topHeader = 0
    case pageView = 1
}

final class UIDetailViewPageViewController: UIViewController, UIScrollViewDelegate {
    private let viewModel: ThreadDetailViewModel
    private var selectedIndex: Int = 0
    private let navigationBar: ThreadDetailTopToolbar
    private let topStaticView: ThreadDetailStaticTopView
    private let pageVC: UIPageViewController
    private var controllers: [UIViewController] = []
    private var viewHasEverAppeared = false
    private var parentScrollLimit: CGFloat = 0
    
    // Table view as vertical container
    private let tableView = UITableView(frame: .zero, style: .plain)
    
    init(viewModel: ThreadDetailViewModel) {
        self.navigationBar = .init(viewModel: viewModel)
        self.topStaticView = .init(viewModel: viewModel)
        var controllers: [UIViewController] = []
        self.controllers = controllers
        self.viewModel = viewModel
        self.pageVC = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)
        super.init(nibName: nil, bundle: nil)
        appendTabControllers()
        setTabControllersDelegate()
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupAppearance()
        setupNavigationToolbar()
        setupPageView()
        setupTableView()
        setupTopStaticView()
        view.backgroundColor = Color.App.bgPrimaryUIColor
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        AppState.shared.objectsContainer.navVM.pushToLinkId(id: "ThreadDetailView-\(viewModel.threadVM?.id ?? 0)")
        if !viewHasEverAppeared {
            viewHasEverAppeared = true
            headerSectionView?.updateTabSelection(animated: false, selectedIndex: 0)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        setParentScrollLimitter()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        let linkId = AppState.shared.objectsContainer.navVM.getLinkId() as? String ?? ""
        if linkId == "ThreadDetailView-\(viewModel.threadVM?.id ?? 0)" {
            viewModel.dismissBySwipe()
        }
    }
    
    private func setupAppearance() {
        view.semanticContentAttribute = Language.isRTL ? .forceRightToLeft : .forceLeftToRight
        view.backgroundColor = UIColor(named: "AppBackgroundPrimary") ?? .systemBackground
        let isDarkModeEnabled = AppSettingsModel.restore().isDarkModeEnabled ?? false
        overrideUserInterfaceStyle = isDarkModeEnabled ? .dark : .light
    }
    
    private func setupNavigationToolbar() {
        navigationBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(navigationBar)
        NSLayoutConstraint.activate([
            navigationBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            navigationBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            navigationBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
    }
    
    // MARK: - Table View Setup
    private func setupTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .clear
        tableView.sectionHeaderTopPadding = 0
        tableView.tableFooterView = UIView()
        
        // HEADER
        tableView.register(ScrollableTabViewSegmentsHeader.self, forHeaderFooterViewReuseIdentifier: String(describing: ScrollableTabViewSegmentsHeader.self))
        
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: navigationBar.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    // MARK: - Top Static view
    private func setupTopStaticView() {
        topStaticView.viewModel = viewModel
        topStaticView.translatesAutoresizingMaskIntoConstraints = false
    }
    
    // MARK: - PageView
    private func setupPageView () {
        addChild(pageVC)
        pageVC.didMove(toParent: self)
        pageVC.delegate = self
        pageVC.dataSource = self
        pageVC.view.semanticContentAttribute = Language.isRTL ? .forceRightToLeft : .forceLeftToRight
        pageVC.setViewControllers([controllers[0]], direction: .forward, animated: false)
        disableAllScrollViewControllers()
        pageVC.view.translatesAutoresizingMaskIntoConstraints = false
    }
    
    // MARK: - Tab Interaction
    @objc private func tabTapped(_ index: Int) {
        guard index != selectedIndex else { return }
        let direction: UIPageViewController.NavigationDirection = index > selectedIndex ? .forward : .reverse
        pageVC.setViewControllers([controllers[index]], direction: direction, animated: true)
        selectedIndex = index
        headerSectionView?.updateTabSelection(animated: true, selectedIndex: selectedIndex)
    }
    
    private var headerSectionView: ScrollableTabViewSegmentsHeader? {
        tableView.headerView(forSection: DetailTableViewSection.pageView.rawValue) as? ScrollableTabViewSegmentsHeader
    }
    
    deinit {
#if DEBUG
        print("deinit called for SelectConversationOrContactListViewController")
#endif
    }
}

// MARK: - UITableView data source
extension UIDetailViewPageViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return DetailTableViewSection.allCases.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.selectionStyle = .none
        
        if indexPath.section == DetailTableViewSection.topHeader.rawValue {
            cell.contentView.addSubview(topStaticView)
            NSLayoutConstraint.activate([
                topStaticView.topAnchor.constraint(equalTo: cell.contentView.topAnchor),
                topStaticView.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor),
                topStaticView.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor),
                topStaticView.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor),
                topStaticView.heightAnchor.constraint(equalToConstant: 320)
            ])
        } else if indexPath.section == DetailTableViewSection.pageView.rawValue {
            cell.contentView.addSubview(pageVC.view)
            NSLayoutConstraint.activate([
                pageVC.view.topAnchor.constraint(equalTo: cell.contentView.topAnchor),
                pageVC.view.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor),
                pageVC.view.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor),
                pageVC.view.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor),
                pageVC.view.heightAnchor.constraint(equalToConstant: view.frame.height)
            ])
        }
        return cell
    }
}

// MARK: - UITableView delegate
extension UIDetailViewPageViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let identifier = String(describing: ScrollableTabViewSegmentsHeader.self)
        guard section == DetailTableViewSection.pageView.rawValue,
              let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: identifier) as? ScrollableTabViewSegmentsHeader
        else { return nil }
        
        let titles = viewModel.tabs.compactMap({ $0.title.bundleLocalized() })
        headerView.onTapped = { [weak self] index in
            self?.tabTapped(index)
        }
        headerView.setButtons(buttonTitles: titles)
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section == DetailTableViewSection.pageView.rawValue ? 44 : 0
    }
}

// MARK: - Handoff scrollView. Pin segmented tabs to top.
extension UIDetailViewPageViewController: UIChildViewScrollDelegate {
    /// Calculate the Y offset at which the segmented header becomes pinned
    private func setParentScrollLimitter() {
        let section = DetailTableViewSection.pageView.rawValue
        let headerRect = tableView.rectForHeader(inSection: section)
        parentScrollLimit = headerRect.origin.y
    }
    
    /// Disable all controllers for UITableViews/CollectionViews initially.
    private func disableAllScrollViewControllers() {
        controllers.compactMap { $0 as? UIViewControllerScrollDelegate }.forEach {
            $0.getInternalScrollView().isScrollEnabled = false
        }
    }
    
    /// Parent table scrolling
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if parentScrollLimit > 0, scrollView.contentOffset.y >= parentScrollLimit {
            tableView.contentOffset.y = parentScrollLimit
            tableView.isScrollEnabled = false
            setCurrentChildScrollEnabled(true)
        }
    }
    
    /// Child scroll view scrolling
    func onChildViewDidScrolled(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y <= 0 {
            tableView.isScrollEnabled = true
            setCurrentChildScrollEnabled(false)
        }
    }
    
    private func setCurrentChildScrollEnabled(_ enabled: Bool) {
        guard
            let childVC = pageVC.viewControllers?.first,
            let scrollView = (childVC as? UIViewControllerScrollDelegate)?.getInternalScrollView()
        else { return }
        scrollView.isScrollEnabled = enabled
    }
}

// MARK: - UIPageViewController Delegate & DataSource
extension UIDetailViewPageViewController: UIPageViewControllerDelegate, UIPageViewControllerDataSource {
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
        headerSectionView?.updateTabSelection(animated: true, selectedIndex: selectedIndex)
        setCurrentChildScrollEnabled(false)
        tableView.isScrollEnabled = true
    }
}

// MARK: - Row Selection.
extension UIDetailViewPageViewController: TabRowItemOnSelectDelegate {
    func onSelect(item: TabRowModel) {
        item.onTap(viewModel: viewModel)
    }
    
    func onSelectMutualGroup(conversation: Conversation) {
        Task { try await goToConversation(conversation) }
    }
    
    /// We have to refetch the conversation because it is not a complete instance of Conversation in mutual response.
    /// So things like admin, public link, and ... don't have any values.
    private func goToConversation(_ conversation: Conversation) async throws {
        guard
            let id = conversation.id,
            let serverConversation = try await GetThreadsReuqester().get(.init(threadIds: [id])).first
        else { return }
        AppState.shared.objectsContainer.navVM.createAndAppend(conversation: serverConversation)
    }
}

// MARK: - Manage tabs.
extension UIDetailViewPageViewController {
    private func appendTabControllers() {
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
    
    private func setTabControllersDelegate() {
        controllers.forEach { vc in
            if let selectableVC = vc as? TabControllerDelegate {
                selectableVC.scrollDelegate = self
                selectableVC.onSelectDelegate = self
                selectableVC.detailVM = viewModel
            }
        }
    }
}
