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
    private let navigationBar: ThreadDetailTopToolbar
    private let topStaticView: ThreadDetailStaticTopView
    private var viewHasEverAppeared = false
    private var parentScrollLimit: CGFloat = 0
    private var pageManager: DetailPageControllerManager?
    private var navVM: NavigationModel { AppState.shared.objectsContainer.navVM }
    
    // Table view as vertical container
    public let tableView = UITableView(frame: .zero, style: .plain)
    
    init(viewModel: ThreadDetailViewModel) {
        self.navigationBar = .init(viewModel: viewModel)
        self.topStaticView = .init(viewModel: viewModel)
        self.viewModel = viewModel
        self.pageManager = DetailPageControllerManager(viewModel: viewModel)
        super.init(nibName: nil, bundle: nil)
        pageManager?.setupPageView(vc: self)
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupAppearance()
        setupNavigationToolbar()
        setupTableView()
        setupTopStaticView()
        view.backgroundColor = Color.App.bgPrimaryUIColor
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navVM.pushToLinkId(id: "ThreadDetailView-\(viewModel.threadVM?.id ?? 0)")
        if !viewHasEverAppeared {
            viewHasEverAppeared = true
            headerSectionView?.updateTabSelection(animated: false, selectedIndex: 0)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        setParentScrollLimitter()
        let inset = view.safeAreaInsets.top + view.safeAreaInsets.bottom + navigationBar.frame.height + (headerSectionView?.frame.height ?? 0)
        pageManager?.setBottomInsetForChilds(bottomInset: inset)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        let linkId = navVM.getLinkId() as? String ?? ""
        if linkId == "ThreadDetailView-\(viewModel.threadVM?.id ?? 0)" {
            viewModel.dismissBySwipe()
        }
    }
    
    private func setupAppearance() {
        view.semanticContentAttribute = Language.isRTL ? .forceRightToLeft : .forceLeftToRight
        view.backgroundColor = UIColor(named: "AppBackgroundPrimary") ?? .systemBackground
        let isDarkMode = AppSettingsModel.restore().isDarkMode
        overrideUserInterfaceStyle = isDarkMode ? .dark : .light
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
    
    // MARK: - Tab Interaction
    @objc private func tabTapped(_ index: Int) {
        guard index != pageManager?.selectedIndex else { return }
        pageManager?.setPage(index: index)
        headerSectionView?.updateTabSelection(animated: true, selectedIndex: index)
    }
    
    var headerSectionView: ScrollableTabViewSegmentsHeader? {
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
            cell.contentView.backgroundColor = .clear
            cell.backgroundColor = .clear
            NSLayoutConstraint.activate([
                topStaticView.topAnchor.constraint(equalTo: cell.contentView.topAnchor),
                topStaticView.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor),
                topStaticView.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor),
                topStaticView.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor),
                topStaticView.heightAnchor.constraint(equalToConstant: topSectionHeight)
            ])
        } else if indexPath.section == DetailTableViewSection.pageView.rawValue, let pageVC = pageManager {
            cell.contentView.addSubview(pageVC.view)
            cell.contentView.backgroundColor = .clear
            cell.backgroundColor = .clear
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
        guard section == DetailTableViewSection.pageView.rawValue,
              let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: ScrollableTabViewSegmentsHeader.identifier) as? ScrollableTabViewSegmentsHeader
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
        parentScrollLimit = topSectionHeight
    }
    
    /// Parent table scrolling
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if parentScrollLimit > 0, scrollView.contentOffset.y >= parentScrollLimit {
            tableView.contentOffset.y = parentScrollLimit
            tableView.isScrollEnabled = false
            pageManager?.setCurrentChildScrollEnabled(true)
        }
    }
    
    /// Child scroll view scrolling
    func onChildViewDidScrolled(_ scrollView: UIScrollView) {
        // Only care when child reaches top
        guard scrollView.contentOffset.y <= 0 else { return }
        // 1. Disable child scrolling
        scrollView.isScrollEnabled = false
        
        // 2. Enable parent scrolling
        tableView.isScrollEnabled = true

        if !scrollView.isDecelerating {
            // 3. Transfer momentum to parent
            tableView.setContentOffset(CGPoint(x: 0, y: 0), animated: true)
        }
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
        navVM.createAndAppend(conversation: serverConversation)
    }
}

// MARK: - Normal Helper methods
extension UIDetailViewPageViewController {
    private var isGroup: Bool {
       return viewModel.thread?.group == true
    }
    
    private var topSectionHeight: CGFloat {
        isGroup ? 280 : 480
    }
}
