//
//  ForwardPickerViewController.swift
//  Talk
//
//  Created by Hamed Hosseini on 6/5/21.
//

import AdditiveUI
import Chat
import SwiftUI
import TalkUI
import TalkViewModels
import TalkModels
import UIKit

final class ForwardPickerViewController: UIViewController {

    private let viewModel = ThreadOrContactPickerViewModel()
    private let onSelect: (Conversation?, Contact?) -> Void
    private let onDisappear: () -> Void

    private let segmentedStack = UIStackView()
    private let underlineView = UIView()
    private var selectedIndex: Int = 0
    private var buttons: [UIButton] = []

    private let pageVC: UIPageViewController
    
    private let searchBar = UISearchBar()

    private lazy var chatVC = ForwardConversationTableViewController(viewModel: viewModel, onSelect: onSelect)
    private lazy var contactVC = ForwardContactTableViewController(viewModel: viewModel, onSelect: onSelect)
    private lazy var controllers: [UIViewController] = [chatVC, contactVC]
    
    private var underlineLeadingConstraint: NSLayoutConstraint? = nil

    init(onSelect: @escaping (Conversation?, Contact?) -> Void, onDisappear: @escaping () -> Void) {
        self.onSelect = onSelect
        self.onDisappear = onDisappear
        self.pageVC = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupAppearance()
        setupSearchBar()
        setupTabs()
        setupPageViewController()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        onDisappear()
    }

    private func setupAppearance() {
        view.semanticContentAttribute = Language.isRTL ? .forceRightToLeft : .forceLeftToRight
        view.backgroundColor = UIColor(named: "AppBackgroundPrimary") ?? .systemBackground
        
        let isDarkModeEnabled = AppSettingsModel.restore().isDarkModeEnabled ?? false
        let style: UIUserInterfaceStyle = isDarkModeEnabled ? .dark : .light
        overrideUserInterfaceStyle = style
        pageVC.overrideUserInterfaceStyle = style
        pageVC.view.overrideUserInterfaceStyle = style
        searchBar.overrideUserInterfaceStyle = style
        segmentedStack.overrideUserInterfaceStyle = style
        underlineView.overrideUserInterfaceStyle = style
    }

    // MARK: - Search Bar
    private func setupSearchBar() {
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        searchBar.placeholder = NSLocalizedString("General.searchHere".bundleLocalized(), comment: "")
        searchBar.delegate = self
        searchBar.searchTextField.font = UIFont.normal(.body)
        searchBar.semanticContentAttribute = Language.isRTL ? .forceRightToLeft : .forceLeftToRight
        view.addSubview(searchBar)
        
        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    // MARK: - Tabs
    private func setupTabs() {
        segmentedStack.axis = .horizontal
        segmentedStack.distribution = .fillEqually
        segmentedStack.translatesAutoresizingMaskIntoConstraints = false
        segmentedStack.semanticContentAttribute = Language.isRTL ? .forceRightToLeft : .forceLeftToRight

        let titles = [
            NSLocalizedString("Tab.chats".bundleLocalized(), comment: ""),
            NSLocalizedString("Tab.contacts".bundleLocalized(), comment: "")
        ]

        for (index, title) in titles.enumerated() {
            let button = UIButton(type: .system)
            button.setTitle(title, for: .normal)
            button.tag = index
            button.titleLabel?.font = UIFont.normal(.body)
            button.addTarget(self, action: #selector(tabTapped(_:)), for: .touchUpInside)
            buttons.append(button)
            segmentedStack.addArrangedSubview(button)
        }

        underlineView.backgroundColor = Color.App.accentUIColor
        underlineView.semanticContentAttribute = Language.isRTL ? .forceRightToLeft : .forceLeftToRight
        underlineView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(segmentedStack)
        view.addSubview(underlineView)

        
        // Define constraints with stored references
        underlineLeadingConstraint = underlineView.leadingAnchor.constraint(equalTo: view.leadingAnchor)
        underlineLeadingConstraint?.isActive = true
        
        NSLayoutConstraint.activate([
            segmentedStack.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
            segmentedStack.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            segmentedStack.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            segmentedStack.heightAnchor.constraint(equalToConstant: 44),

            underlineView.topAnchor.constraint(equalTo: segmentedStack.bottomAnchor),
            underlineView.heightAnchor.constraint(equalToConstant: 2),
            underlineView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.5)
        ])

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

        let underlinePosition = CGFloat(selectedIndex) / CGFloat(buttons.count)
        underlineLeadingConstraint?.constant = view.frame.width * underlinePosition
        
        if animated {
            UIView.animate(withDuration: 0.15) {
                self.view.layoutIfNeeded()
            }
        } else {
            self.view.layoutIfNeeded()
        }
    }
    
    deinit {
#if DEBUG
        print("deinit called for SelectConversationOrContactListViewController")
#endif
    }
}

// MARK: - UISearchBarDelegate
extension ForwardPickerViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        viewModel.onTextChanged(searchText)
    }
}

// MARK: - UIPageViewController Delegate & DataSource
extension ForwardPickerViewController: UIPageViewControllerDelegate, UIPageViewControllerDataSource {
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
