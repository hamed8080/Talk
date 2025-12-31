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

final class UIDetailViewPageViewController: UIViewController {
    
    private let viewModel: ThreadDetailViewModel
    private let onDisappear: () -> Void

    private let segmentedStackButtonsScrollView = UIScrollView()
    private let segmentedStack = UIStackView()
    private let underlineView = UIView()
    private var selectedIndex: Int = 0
    private var buttons: [UIButton] = []

    private let navigationBar: ThreadDetailTopToolbar
    private let topStaticView: ThreadDetailStaticTopView
    private let pageVC: UIPageViewController
    private var controllers: [UIViewController] = []
    
    private var underlineLeadingConstraint: NSLayoutConstraint? = nil

    init(viewModel: ThreadDetailViewModel, onDisappear: @escaping () -> Void) {
        self.navigationBar = .init(viewModel: viewModel)
        self.topStaticView = .init(viewModel: viewModel)
        var controllers: [UIViewController] = []
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
                    controllers.append(MutualGroupsTableViewController(viewModel: viewModel, onSelect: { model in
                        
                    }))
                }
            }
        }
        
        self.controllers = controllers
        self.viewModel = viewModel
        self.onDisappear = onDisappear
        self.pageVC = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)
        super.init(nibName: nil, bundle: nil)
        
        controllers.forEach { vc in
            if let selectableVC = vc as? TabControllerDelegate {
                selectableVC.onSelectDelegate = self
                selectableVC.detailVM = viewModel
            }
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupAppearance()
        setupNavigationToolbar()
        setupTopStaticView()
        setupTabs()
        setupPageViewController()
        view.backgroundColor = Color.App.bgPrimaryUIColor
        scrollToSelectedIndex()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        onDisappear()
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
    
    // MARK: - Top Static view
    private func setupTopStaticView() {
        topStaticView.viewModel = viewModel
        topStaticView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(topStaticView)
        NSLayoutConstraint.activate([
            topStaticView.topAnchor.constraint(equalTo: navigationBar.bottomAnchor, constant: 0),
            topStaticView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topStaticView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topStaticView.heightAnchor.constraint(lessThanOrEqualToConstant: 320),
        ])
    }

    // MARK: - Tabs
    private func setupTabs() {
        segmentedStack.axis = .horizontal
        segmentedStack.distribution = .fill
        segmentedStack.translatesAutoresizingMaskIntoConstraints = false
        segmentedStack.semanticContentAttribute = Language.isRTL ? .forceRightToLeft : .forceLeftToRight

        segmentedStackButtonsScrollView.translatesAutoresizingMaskIntoConstraints = false
        segmentedStackButtonsScrollView.showsHorizontalScrollIndicator = false
        segmentedStackButtonsScrollView.showsVerticalScrollIndicator = false
        segmentedStackButtonsScrollView.semanticContentAttribute = Language.isRTL ? .forceRightToLeft : .forceLeftToRight
        segmentedStackButtonsScrollView.addSubview(segmentedStack)
        
        underlineView.backgroundColor = Color.App.accentUIColor
        underlineView.semanticContentAttribute = Language.isRTL ? .forceRightToLeft : .forceLeftToRight
        underlineView.translatesAutoresizingMaskIntoConstraints = false
        segmentedStackButtonsScrollView.addSubview(underlineView)

        let titles = viewModel.tabs.compactMap({ $0.title.bundleLocalized() })

        for (index, title) in titles.enumerated() {
            let button = UIButton(type: .system)
            button.setTitle(title, for: .normal)
            button.tag = index
            button.titleLabel?.font = UIFont.normal(.body)
            button.translatesAutoresizingMaskIntoConstraints = false
            button.addTarget(self, action: #selector(tabTapped(_:)), for: .touchUpInside)
            buttons.append(button)
            segmentedStack.addArrangedSubview(button)
        }
        
        view.addSubview(segmentedStackButtonsScrollView)
        
        underlineLeadingConstraint = underlineView.leadingAnchor.constraint(equalTo: segmentedStack.leadingAnchor)
        underlineLeadingConstraint?.isActive = true
        
        NSLayoutConstraint.activate([
            segmentedStackButtonsScrollView.topAnchor.constraint(equalTo: topStaticView.bottomAnchor, constant: 8),
            segmentedStackButtonsScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            segmentedStackButtonsScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            segmentedStackButtonsScrollView.heightAnchor.constraint(equalToConstant: 44),
            
            segmentedStack.topAnchor.constraint(equalTo: segmentedStackButtonsScrollView.contentLayoutGuide.topAnchor),
            segmentedStack.bottomAnchor.constraint(equalTo: segmentedStackButtonsScrollView.contentLayoutGuide.bottomAnchor),
            segmentedStack.leadingAnchor.constraint(equalTo: segmentedStackButtonsScrollView.contentLayoutGuide.leadingAnchor),
            segmentedStack.trailingAnchor.constraint(equalTo: segmentedStackButtonsScrollView.contentLayoutGuide.trailingAnchor),
            segmentedStack.heightAnchor.constraint(equalTo: segmentedStackButtonsScrollView.contentLayoutGuide.heightAnchor),

            underlineView.bottomAnchor.constraint(equalTo: segmentedStackButtonsScrollView.contentLayoutGuide.bottomAnchor),
            underlineView.heightAnchor.constraint(equalToConstant: 2),
            underlineView.widthAnchor.constraint(equalToConstant: 96)
        ])
        
        for button in buttons {
            NSLayoutConstraint.activate([
                button.widthAnchor.constraint(equalToConstant: 96),
                button.heightAnchor.constraint(equalToConstant: 44)
            ])
        }

        updateTabSelection(animated: false)
    }

    // MARK: - Page View Controller
    private func setupPageViewController() {
        addChild(pageVC)
        view.addSubview(pageVC.view)
        pageVC.didMove(toParent: self)
        pageVC.delegate = self
        pageVC.dataSource = self
        pageVC.view.semanticContentAttribute = Language.isRTL ? .forceRightToLeft : .forceLeftToRight

        pageVC.setViewControllers([controllers[0]], direction: .forward, animated: false)

        pageVC.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            pageVC.view.topAnchor.constraint(equalTo: underlineView.bottomAnchor),
            pageVC.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pageVC.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pageVC.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // MARK: - Tab Interaction
    @objc private func tabTapped(_ sender: UIButton) {
        let index = sender.tag
        guard index != selectedIndex else { return }
        let direction: UIPageViewController.NavigationDirection = index > selectedIndex ? .forward : .reverse
        pageVC.setViewControllers([controllers[index]], direction: direction, animated: true)
        selectedIndex = index
        updateTabSelection(animated: true)
    }

    private func updateTabSelection(animated: Bool) {
        for (i, button) in buttons.enumerated() {
            button.setTitleColor(i == selectedIndex ? .label : .secondaryLabel, for: .normal)
        }

        let underlinePosition = CGFloat(selectedIndex) * 96
        underlineLeadingConstraint?.constant = underlinePosition
        
        if animated {
            UIView.animate(withDuration: 0.15) {
                self.view.layoutIfNeeded()
            }
        } else {
            self.view.layoutIfNeeded()
        }
    
        scrollToSelectedIndex()
    }
    
    private func scrollToSelectedIndex() {
        guard selectedIndex < buttons.count else { return }

          let button = buttons[selectedIndex]

          // Convert button frame into scrollView's content space
          let rect = segmentedStack.convert(button.frame, to: segmentedStackButtonsScrollView)

          segmentedStackButtonsScrollView.scrollRectToVisible(
              rect.insetBy(dx: -16, dy: 0), // optional padding
              animated: true
          )
    }

    deinit {
#if DEBUG
        print("deinit called for SelectConversationOrContactListViewController")
#endif
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
        updateTabSelection(animated: true)
    }
}

extension UIDetailViewPageViewController: TabRowItemOnSelectDelegate {
    func onSelect(item: TabRowModel) {
        item.onTap(viewModel: viewModel)
    }
}

//struct ThreadDetailView: View {
//    @EnvironmentObject var viewModel: ThreadDetailViewModel
//    @Environment(\.dismiss) private var dismiss
//    @State private var viewWidth: CGFloat = 0
//
//    var body: some View {
//        ScrollViewReader { proxy in
//            ScrollView(.vertical) {
//                VStack(spacing: 0) {
//                    DetailSectionContainer()
//                        .id("DetailSectionContainer")
//                    if viewWidth != 0 {
////                        DetailTabContainer(maxWidth: viewWidth)
////                            .id("DetailTabContainer")
//                    }
//                }
//                .frame(maxWidth: viewWidth == 0 ? .infinity : viewWidth)
//            }
//            .onAppear {
//                viewModel.scrollViewProxy = proxy
//            }
//        }
//        .navigationBarBackButtonHidden(true)
//        .background(Color.App.bgPrimary)
//        .environmentObject(viewModel)
//        .background(frameReader)
//        .safeAreaInset(edge: .top, spacing: 0) { DetailToolbarContainer() }
//        .background(DetailAddOrEditContactSheetView())
//        .onAppear {
//            AppState.shared.objectsContainer.navVM.pushToLinkId(id: "ThreadDetailView-\(viewModel.threadVM?.id ?? 0)")
//        }
//        .onDisappear {
//            Task(priority: .background) {
//                viewModel.threadVM?.searchedMessagesViewModel.reset()
//            }
//            
//            /// We make sure user is not moving to edit thread detail or contact
//            let linkId = AppState.shared.objectsContainer.navVM.getLinkId() as? String ?? ""
//            if linkId == "ThreadDetailView-\(viewModel.threadVM?.id ?? 0)" {
//                viewModel.dismissBySwipe()
//            }
//        }
//    }
//    
//    private var frameReader: some View {
//        GeometryReader { reader in
//            Color.clear.onAppear {
//                if viewWidth == 0 {
//                    self.viewWidth = reader.size.width
//                }
//            }
//        }
//    }
//}

//
//struct DetailTabContainer: View {
//    @EnvironmentObject var viewModel: ThreadDetailViewModel
//    @State private var tabs: [TalkUI.Tab] = []
//    @State private var selectedTabIndex = 0
//    let maxWidth: CGFloat
//
//    var body: some View {
//        CustomDetailTabView(tabs: tabs, tabButtons: { tabButtons } )
//            .environmentObject(viewModel.threadVM?.participantsViewModel ?? .init())
//            .selectedTabIndx(index: selectedTabIndex)
//            .onAppear {
//                if tabs.isEmpty {
//                    makeTabs()
//                }
//            }
//            .onChange(of: viewModel.thread?.closed) { newValue in
//                if newValue == true {
//                    withAnimation {
//                        makeTabs()
//                    }
//                }
//            }
//    }
//
//    private var tabButtons: TabViewButtonsContainer {
//        TabViewButtonsContainer(selectedTabIndex: $selectedTabIndex, tabs: tabs)
//    }
//}
//
//@available(iOS 16.4, macOS 13.3, tvOS 16.4, watchOS 9.4, *)
//struct DetailTabContainer_Previews: PreviewProvider {
//    static var previews: some View {
//        DetailTabContainer(maxWidth: 400)
//    }
//}
