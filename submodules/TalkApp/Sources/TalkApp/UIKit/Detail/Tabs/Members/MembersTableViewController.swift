//
//  MembersTableViewController.swift
//  Talk
//
//  Created by Hamed Hosseini on 9/23/21.
//

import Foundation
import UIKit
import Chat
import SwiftUI
import TalkViewModels
import TalkModels
import TalkExtensions
import TalkUI

class MembersTableViewController: UIViewController {
    var dataSource: UITableViewDiffableDataSource<MembersListSection, MemberItem>!
    var tableView: UITableView = UITableView(frame: .zero)
    let viewModel: ParticipantsViewModel
    static let searchIdentifier = "MEMBER-SEARCH-CELL"
    static let addParticipantIdentifier = "MEMBER-ADD-PARTICIPANT-CELL"
    static let resuableIdentifier = "MEMBER-ROW"
    static let nothingFoundIdentifier = "NOTHING-FOUND-MEMBER-ROW"
    private var contextMenuContainer: ContextMenuContainerView?
    
    init(viewModel: ParticipantsViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        viewModel.delegate = self
        tableView.register(MemberSearchCell.self, forCellReuseIdentifier: MembersTableViewController.searchIdentifier)
        tableView.register(MemberAddParticipantCell.self, forCellReuseIdentifier: MembersTableViewController.addParticipantIdentifier)
        tableView.register(MemberCell.self, forCellReuseIdentifier: MembersTableViewController.resuableIdentifier)
        tableView.register(NothingFoundCell.self, forCellReuseIdentifier: MembersTableViewController.nothingFoundIdentifier)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.semanticContentAttribute = Language.isRTL ? .forceRightToLeft : .forceLeftToRight
        tableView.semanticContentAttribute = Language.isRTL ? .forceRightToLeft : .forceLeftToRight
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.rowHeight = 82
        tableView.delegate = self
        tableView.allowsMultipleSelection = false
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
        configureDataSource()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        contextMenuContainer = .init(delegate: self)
        if viewModel.participants.count == 0 {
            Task {
                await viewModel.getParticipants()
            }
        }
    }
}

extension MembersTableViewController {
    
    private func configureDataSource() {
        dataSource = UITableViewDiffableDataSource(tableView: tableView) { [weak self] (tableView, indexPath, item) -> UITableViewCell? in
            guard let self = self else { return nil }
            switch item {
            case .searchTextFields:
                let cell = tableView.dequeueReusableCell(
                    withIdentifier: MembersTableViewController.searchIdentifier,
                    for: indexPath
                ) as? MemberSearchCell
                cell?.viewModel = viewModel
                return cell
            case .addParticipantButton:
                let cell = tableView.dequeueReusableCell(
                    withIdentifier: MembersTableViewController.addParticipantIdentifier,
                    for: indexPath
                ) as? MemberAddParticipantCell
                cell?.conversation = viewModel.thread
                return cell
            case .item(let item):
                let cell = tableView.dequeueReusableCell(
                    withIdentifier: MembersTableViewController.resuableIdentifier,
                    for: indexPath
                ) as? MemberCell
                
                // Set properties
                cell?.viewModel = viewModel
                cell?.setItem(item.participnat, item.image)
                cell?.onContextMenu = { [weak self] sender in
                    guard let self = self else { return }
                    if sender.state == .began {
                        /// We have to fetch new indexPath the above index path is the old one if we pin/unpin a thread
                        if let index = viewModel.list.firstIndex(where: { $0.id == item.participnat.id }), viewModel.list[index].id != AppState.shared.user?.id {
                            showContextMenu(IndexPath(row: index, section: indexPath.section), contentView: UIView())
                        }
                    }
                }
                return cell
            case .noResult:
                let cell = tableView.dequeueReusableCell(
                    withIdentifier: MembersTableViewController.nothingFoundIdentifier,
                    for: indexPath
                ) as? NothingFoundCell
                return cell
            }
        }
    }
}

extension MembersTableViewController: UIMembersViewControllerDelegate {
    func apply(snapshot: NSDiffableDataSourceSnapshot<MembersListSection, MemberItem>, animatingDifferences: Bool) {
        dataSource.apply(snapshot, animatingDifferences: animatingDifferences)
    }
    
    func updateImage(image: UIImage?, id: Int) {
        cell(id: id)?.updateImage(image)
    }
    
    private func cell(id: Int) -> MemberCell? {
        guard let index = viewModel.list.firstIndex(where: { $0.id == id }) else { return nil }
        return tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? MemberCell
    }
}

extension MembersTableViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard
            let item = dataSource.itemIdentifier(for: indexPath),
            case .item(let participant, let uIImage) = item,
            participant.id != AppState.shared.user?.id
        else { return }
        Task {
            try await AppState.shared.objectsContainer.navVM.openThread(participant: participant)
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let conversation = dataSource.itemIdentifier(for: indexPath) else { return }
        Task {
            try await viewModel.loadMore()
        }
    }
    
    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        if dataSource.itemIdentifier(for: indexPath) == .searchTextFields {
            return false
        }
        return true
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let item = dataSource.itemIdentifier(for: indexPath)
        if case .item(let participant, let uIImage) = item {
            return 82
        }
        return 48
    }
}

extension MembersTableViewController: ContextMenuDelegate {
    func showContextMenu(_ indexPath: IndexPath?, contentView: UIView) {
        guard
            let indexPath = indexPath,
            let item = dataSource.itemIdentifier(for: indexPath),
            case let .item(participant, image) = item
        else { return }
        
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred(intensity: 1.0)
        let cell = tableView.cellForRow(at: indexPath) as? MemberCell
        let contentView = MemberRowContextMenuUIKit(viewModel: viewModel, participant: participant, image: image, container: contextMenuContainer)
        contextMenuContainer?.setContentView(contentView, indexPath: indexPath)
        contextMenuContainer?.show()
    }
    
    func dismissContextMenu(indexPath: IndexPath?) {
        
    }
}

final class MemberSearchCell: UITableViewCell {
    
    // MARK: - View Models
    var viewModel: ParticipantsViewModel?
    
    // MARK: - UI Components
    private let searchContainer = UIStackView()
    private let iconView = UIImageView()
    private let textField = UITextField()
    private let menuButton = UIButton(type: .system)
    
    // MARK: - State
    private var showPopover = false
    
    // MARK: - Init
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
        setupPopover()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup UI
    private func setupUI() {
        /// Background color once is selected or tapped
        selectionStyle = .none
        
        semanticContentAttribute = Language.isRTL ? .forceRightToLeft : .forceLeftToRight
        contentView.semanticContentAttribute = Language.isRTL ? .forceRightToLeft : .forceLeftToRight
        translatesAutoresizingMaskIntoConstraints = true
        contentView.backgroundColor = Color.App.dividerSecondaryUIColor
        backgroundColor = Color.App.dividerSecondaryUIColor
        
        // Container stack
        let hStack = UIStackView()
        hStack.axis = .horizontal
        hStack.alignment = .center
        hStack.spacing = 12
        hStack.semanticContentAttribute = Language.isRTL ? .forceRightToLeft : .forceLeftToRight
        hStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(hStack)
        
        NSLayoutConstraint.activate([
            hStack.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            hStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            hStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            hStack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        // Search box
        searchContainer.axis = .horizontal
        searchContainer.alignment = .center
        searchContainer.spacing = 8
        searchContainer.semanticContentAttribute = Language.isRTL ? .forceRightToLeft : .forceLeftToRight
        
        iconView.image = UIImage(systemName: "magnifyingglass")
        iconView.tintColor = Color.App.textSecondaryUIColor
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.semanticContentAttribute = Language.isRTL ? .forceRightToLeft : .forceLeftToRight
        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: 22),
            iconView.heightAnchor.constraint(equalToConstant: 22)
        ])
        
        textField.placeholder = "General.searchHere".bundleLocalized()
        textField.font = UIFont.normal(.body)
        textField.returnKeyType = .done
        textField.delegate = self
        textField.textAlignment = Language.isRTL ? .right : .left
        textField.semanticContentAttribute = Language.isRTL ? .forceRightToLeft : .forceLeftToRight
        textField.addTarget(self, action: #selector(textDidChange(_:)), for: .editingChanged)
        
        searchContainer.addArrangedSubview(iconView)
        searchContainer.addArrangedSubview(textField)
        hStack.addArrangedSubview(searchContainer)
        hStack.addArrangedSubview(menuButton)
        
        // Search Type Button
        updateSearchTypeButton()
    }
    
    private func updateSearchTypeButton() {
        let title = viewModel?.searchType.rawValue ?? ""
        let image = UIImage(systemName: "chevron.down")?.withConfiguration(UIImage.SymbolConfiguration(pointSize: 12, weight: .medium))
        
        var config = UIButton.Configuration.plain()
        config.title = title
        config.image = image
        config.imagePadding = 4
        config.baseForegroundColor = Color.App.textSecondaryUIColor
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attrs in
            var newAttrs = attrs
            newAttrs.font = UIFont.bold(.caption3)
            return newAttrs
        }
        
        menuButton.configuration = config
    }
    
    // MARK: - Popover Setup
    private func setupPopover() {
        // Configure menu button
        menuButton.translatesAutoresizingMaskIntoConstraints = false
        menuButton.showsMenuAsPrimaryAction = true
        menuButton.semanticContentAttribute = Language.isRTL ? .forceRightToLeft : .forceLeftToRight
        
        // Default value
        let defualtType = SearchParticipantType.name
        menuButton.setTitle(defualtType.rawValue.bundleLocalized() ?? "", for: .normal)
        viewModel?.searchType = defualtType
        
        let actions = SearchParticipantType.allCases.filter({ $0 != .admin }).compactMap({ type in
            UIAction(title: type.rawValue.bundleLocalized(), image: nil) { [weak self] _ in
                self?.viewModel?.searchType = type
                self?.menuButton.setTitle(type.rawValue.bundleLocalized() ?? "", for: .normal)
            }
        })
        menuButton.menu = UIMenu(title: "", children: actions)
    }
    
    @objc private func textDidChange(_ textField: UITextField) {
        viewModel?.searchText = textField.text ?? ""
    }
}

// MARK: - UITextFieldDelegate
extension MemberSearchCell: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

final class MemberAddParticipantCell: UITableViewCell {

    // MARK: - UI Components
    private let container = UIView()
    private let addParticipantImageView = UIImageView(image: UIImage(systemName: "person.badge.plus"))
    private let addParticipantLabel = UILabel()
    
    // MARK: - State
    var conversation: Conversation?
    
    // MARK: - Init
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup UI
    private func setupUI() {
        /// Background color once is selected or tapped
        selectionStyle = .none
        
        semanticContentAttribute = Language.isRTL ? .forceRightToLeft : .forceLeftToRight
        contentView.semanticContentAttribute = Language.isRTL ? .forceRightToLeft : .forceLeftToRight
        translatesAutoresizingMaskIntoConstraints = true
        contentView.backgroundColor = .clear
        backgroundColor = .clear
        
        container.translatesAutoresizingMaskIntoConstraints = false
        container.semanticContentAttribute = Language.isRTL ? .forceRightToLeft : .forceLeftToRight
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(onAddParticipantTapped))
        container.addGestureRecognizer(tapGesture)
        contentView.addSubview(container)
        
        addParticipantLabel.translatesAutoresizingMaskIntoConstraints = false
        addParticipantLabel.text = "Thread.invite".bundleLocalized()
        addParticipantLabel.font = UIFont.normal(.body)
        addParticipantLabel.textAlignment = Language.isRTL ? .right : .left
        addParticipantLabel.textColor = Color.App.accentUIColor
        container.addSubview(addParticipantLabel)
       
        addParticipantImageView.translatesAutoresizingMaskIntoConstraints = false
        addParticipantImageView.tintColor = Color.App.accentUIColor
        addParticipantImageView.contentMode = .scaleAspectFit
        container.addSubview(addParticipantImageView)
        
        NSLayoutConstraint.activate([
            container.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            container.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            container.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            container.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            addParticipantImageView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 0),
            addParticipantImageView.centerYAnchor.constraint(equalTo: container.centerYAnchor, constant: 0),
            addParticipantImageView.widthAnchor.constraint(equalToConstant: 26),
            addParticipantImageView.heightAnchor.constraint(equalToConstant: 22),
            
            addParticipantLabel.leadingAnchor.constraint(equalTo: addParticipantImageView.trailingAnchor, constant: 0),
            addParticipantLabel.centerYAnchor.constraint(equalTo: addParticipantImageView.centerYAnchor, constant: 2),
            addParticipantLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            addParticipantLabel.heightAnchor.constraint(equalToConstant: 16),
        ])
    }
    
    @objc private func onAddParticipantTapped() {
        let rootView = AddParticipantsToThreadView() { [weak self] contacts in
            self?.onSelectedContacts(Array(contacts))
        }
        .injectAllObjects()
        .environment(\.layoutDirection, Language.isRTL ? .rightToLeft : .leftToRight)
        
        let vc = UIHostingController(rootView: rootView)
        vc.modalPresentationStyle = .formSheet
        guard let parentVC = parentViewController else { return }
        parentVC.present(vc, animated: true)
    }
    
    private func onSelectedContacts(_ contacts: [Contact]) {
        if conversation?.type?.isPrivate == true, conversation?.group == true {
            AppState.shared.objectsContainer.appOverlayVM.dialogView = AnyView(
                AdminLimitHistoryTimeDialog(threadId: conversation?.id ?? -1) { [weak self] historyTime in
                    guard let self = self else { return }
                    if let historyTime = historyTime {
                        add(contacts, historyTime)
                    } else {
                        add(contacts)
                    }
                }
                    .injectAllObjects()
                    .environmentObject(AppState.shared.objectsContainer)
            )
        } else {
            add(contacts)
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        if touches.first?.view == container {
            setDimColor(dim: true)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        if touches.first?.view == container {
            setDimColor(dim: false)
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        if touches.first?.view == container {
            setDimColor(dim: false)
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        if touches.first?.view == container {
            setDimColor(dim: false)
        }
    }
    
    private func setDimColor(dim: Bool) {
        container.alpha = dim ? 0.5 : 1.0
    }
    
    private func add(_ contacts: [Contact], _ historyTime: UInt? = nil) {
        guard let threadId = conversation?.id else { return }
        let invitees: [Invitee] = contacts.compactMap{ .init(id: $0.user?.username, idType: .username, historyTime: historyTime) }
        let req = AddParticipantRequest(invitees: invitees, threadId: threadId)
        Task { @ChatGlobalActor in
            ChatManager.activeInstance?.conversation.participant.add(req)
        }
    }
}

// MARK: - UIView helper
private extension UIView {
    var parentViewController: UIViewController? {
        var parentResponder: UIResponder? = self
        while let next = parentResponder?.next {
            if let vc = next as? UIViewController { return vc }
            parentResponder = next
        }
        return nil
    }
}

//
//struct MembersTabView: View {
//    @EnvironmentObject var viewModel: ParticipantsViewModel
//    @EnvironmentObject var detailViewModel: ThreadDetailViewModel
//    
//    var body: some View {
//        LazyVStack(spacing: 0) {
//            ParticipantSearchView()
//            AddParticipantButton(conversation: viewModel.thread)
//                .listRowSeparatorTint(.gray.opacity(0.2))
//                .listRowBackground(Color.App.bgPrimary)
//            StickyHeaderSection(header: "", height: 10)
//
//            if viewModel.searchedParticipants.count > 0 || !viewModel.searchText.isEmpty {
//                StickyHeaderSection(header: "Memebers.searchedMembers")
//                ForEach(viewModel.searchedParticipants) { participant in
//                    ParticipantRowContainer(participant: participant, isSearchRow: true)
//                }
//                /// An empty view to pull the view to top even when viewModel.searchedParticipants.count
//                /// but the searchText is not empty.
//                Rectangle()
//                    .fill(.clear)
//                    .frame(height: viewModel.searchedParticipants.count < 10 ? 256 : 0)
//                    .onAppear {
//                        detailViewModel.scrollViewProxy?.scrollTo("DetailTabContainer", anchor: .top)
//                    }
//            } else {
//                ForEach(viewModel.sorted) { participant in
//                    ParticipantRowContainer(participant: participant, isSearchRow: false)
//                }
//            }
//        }
//        .animation(.easeInOut, value: viewModel.participants.count)
//        .animation(.easeInOut, value: viewModel.searchedParticipants.count)
//        .animation(.easeInOut, value: viewModel.searchText)
//        .animation(.easeInOut, value: viewModel.lazyList.isLoading)
//        .ignoresSafeArea(.all)
//        .padding(.bottom)
//        .onAppear {
//            if viewModel.participants.count == 0 {
//                Task {
//                    await viewModel.getParticipants()
//                }
//            }
//        }
//    }
//}
//
//struct ParticipantRowContainer: View {
//    @State private var showPopover = false
//    @EnvironmentObject var viewModel: ParticipantsViewModel
//    let participant: Participant
//    let isSearchRow: Bool
//    @State private var clickDate = Date()
//    var separatorColor: Color {
//        if !isSearchRow {
//            return viewModel.participants.last == participant ? Color.clear : Color.App.dividerPrimary
//        } else {
//            return viewModel.searchedParticipants.last == participant ? Color.clear : Color.App.dividerPrimary
//        }
//    }
//
//    var body: some View {
//        ParticipantRow(participant: participant)
//            .id("\(isSearchRow ? "SearchRow" : "Normal")\(participant.id ?? 0)")
//            .padding(.vertical)
//            .background(Color.App.bgPrimary)
//            .overlay(alignment: .bottom) {
//                Rectangle()
//                    .fill(separatorColor)
//                    .frame(height: 0.5)
//                    .padding(.leading, 64)
//            }
//            .onAppear {
//                if viewModel.participants.last == participant {
//                    Task {
//                        await viewModel.loadMore()
//                    }
//                }
//            }
//            .onTapGesture {
//                if !isMe {
//                    if clickDate.advanced(by: 0.5) > .now {
//                        return
//                    }
//                    Task {
//                        clickDate = Date()
//                        try await AppState.shared.objectsContainer.navVM.openThread(participant: participant)
//                    }
//                }
//            }
//            .onLongPressGesture {
//                if !isMe, viewModel.thread?.admin == true {
//                    showPopover.toggle()
//                }
//            }
//            .popover(isPresented: $showPopover, attachmentAnchor: .point(.center), arrowEdge: .top) {
//                if #available(iOS 16.4, macOS 13.3, tvOS 16.4, watchOS 9.4, *) {
//                    popoverBody
//                    .presentationCompactAdaptation(horizontal: .popover, vertical: .popover)
//                } else {
//                    popoverBody
//                }
//            }
//    }
//    
//    private var isMe: Bool {
//        participant.id == AppState.shared.user?.id
//    }
//    
//    private var popoverBody: some View {
//        VStack(alignment: .leading, spacing: 0) {
//            if !isMe, viewModel.thread?.admin == true, (participant.admin ?? false) == false {
//                ContextMenuButton(title: "Participant.addAdminAccess".bundleLocalized(), image: "person.crop.circle.badge.plus", bundle: Language.preferedBundle, isRTL: Language.isRTL) {
//                    viewModel.makeAdmin(participant)
//                    showPopover.toggle()
//                }
//            }
//
//            if !isMe, viewModel.thread?.admin == true, (participant.admin ?? false) == true {
//                ContextMenuButton(title: "Participant.removeAdminAccess".bundleLocalized(), image: "person.crop.circle.badge.minus", bundle: Language.preferedBundle, isRTL: Language.isRTL) {
//                    viewModel.removeAdminRole(participant)
//                    showPopover.toggle()
//                }
//            }
//
//            if !isMe, viewModel.thread?.admin == true {
//                ContextMenuButton(title: "General.delete".bundleLocalized(), image: "trash", bundle: Language.preferedBundle, isRTL: Language.isRTL) {
//                    let dialog = AnyView(
//                        DeleteParticipantDialog(participant: participant)
//                            .environmentObject(viewModel)
//                    )
//                    AppState.shared.objectsContainer.appOverlayVM.dialogView = dialog
//                    showPopover.toggle()
//                }
//                .foregroundStyle(Color.App.red)
//            }
//        }
//        .font(Font.fBody)
//        .foregroundColor(.primary)
//        .frame(width: 246)
//        .background(MixMaterialBackground())
//        .clipShape(RoundedRectangle(cornerRadius:((12))))
//    }
//}
//
//struct AddParticipantButton: View {
//    @State var presentSheet: Bool = false
//    let conversation: Conversation?
//
//    var body: some View {
//        if conversation?.group == true, conversation?.admin == true{
//            Button {
//                presentSheet.toggle()
//            } label: {
//                HStack(spacing: 24) {
//                    Image(systemName: "person.badge.plus")
//                        .resizable()
//                        .scaledToFit()
//                        .frame(width: 24, height: 16)
//                        .foregroundStyle(Color.App.accent)
//                    Text("Thread.invite")
//                        .font(.fBody)
//                    Spacer()
//                }
//                .foregroundStyle(Color.App.accent)
//                .padding(EdgeInsets(top: 16, leading: 24, bottom: 16, trailing: 24))
//            }
//            .sheet(isPresented: $presentSheet) {
//                AddParticipantsToThreadView() { contacts in
//                    addParticipantsToThread(contacts)
//                    presentSheet.toggle()
//                }
//                .environment(\.layoutDirection, Language.isRTL ? .rightToLeft : .leftToRight)
//            }
//        }
//    }
//
//    public func addParticipantsToThread(_ contacts: ContiguousArray<Contact>) {
//        if conversation?.type?.isPrivate == true, conversation?.group == true {
//            AppState.shared.objectsContainer.appOverlayVM.dialogView = AnyView(
//                AdminLimitHistoryTimeDialog(threadId: conversation?.id ?? -1) { historyTime in
//                    if let historyTime = historyTime {
//                        add(contacts, historyTime)
//                    } else {
//                        add(contacts)
//                    }
//                }
//                    .environmentObject(AppState.shared.objectsContainer)
//            )
//        } else {
//            add(contacts)
//        }
//    }
//
//    private func add(_ contacts: ContiguousArray<Contact>, _ historyTime: UInt? = nil) {
//        guard let threadId = conversation?.id else { return }
//        let invitees: [Invitee] = contacts.compactMap{ .init(id: $0.user?.username, idType: .username, historyTime: historyTime) }
//        let req = AddParticipantRequest(invitees: invitees, threadId: threadId)
//        Task { @ChatGlobalActor in
//            ChatManager.activeInstance?.conversation.participant.add(req)
//        }
//    }
//}
//
//struct ParticipantSearchView: View {
//    @EnvironmentObject var viewModel: ParticipantsViewModel
//    @EnvironmentObject var detailViewModel: ThreadDetailViewModel
//    @State private var showPopover = false
//    @FocusState private var focusState: Bool
//
//    var body: some View {
//        HStack(spacing: 12) {
//            HStack {
//                Image(systemName: "magnifyingglass")
//                    .resizable()
//                    .scaledToFit()
//                    .foregroundStyle(Color.App.textSecondary)
//                    .frame(width: 16, height: 16)
//                TextField("General.searchHere".bundleLocalized(), text: $viewModel.searchText)
//                    .frame(minWidth: 0, minHeight: 48)
//                    .submitLabel(.done)
//                    .font(.fBody)
//                    .focused($focusState)
//                    .onChange(of: focusState) { focused in
//                        if focused {
//                            withAnimation {
//                                detailViewModel.scrollViewProxy?.scrollTo("DetailTabContainer", anchor: .top)
//                            }
//                        }
//                    }
//            }
//            Spacer()
//
//            Button {
//                showPopover.toggle()
//            } label: {
//                HStack {
//                    Text(viewModel.searchType.rawValue)
//                        .font(.fBoldCaption3)
//                        .foregroundColor(Color.App.textSecondary)
//                    Image(systemName: "chevron.down")
//                        .resizable()
//                        .scaledToFit()
//                        .frame(width: 8, height: 12)
//                        .fontWeight(.medium)
//                        .foregroundColor(Color.App.textSecondary)
//                }
//            }
//            .popover(isPresented: $showPopover, arrowEdge: .bottom) {
//                if #available(iOS 16.4, macOS 13.3, tvOS 16.4, watchOS 9.4, *) {
//                    popoverBody
//                    .presentationCompactAdaptation(.popover)
//                } else {
//                    popoverBody
//                }
//            }
//        }
//        .padding(EdgeInsets(top: 8, leading: 8, bottom: 0, trailing: 8))
//        .background(Color.App.dividerSecondary)
//        .animation(.easeInOut, value: viewModel.searchText)
//    }
//    
//    private var popoverBody: some View {
//        VStack(alignment: .leading, spacing: 8) {
//            ForEach(SearchParticipantType.allCases.filter({$0 != .admin })) { item in
//                Button {
//                    withAnimation {
//                        viewModel.searchType = item
//                        showPopover.toggle()
//                    }
//                } label: {
//                    Text(item.rawValue)
//                        .font(.fBoldCaption3)
//                        .foregroundColor(Color.App.textSecondary)
//                }
//                .padding(8)
//            }
//        }
//        .padding(8)
//    }
//}

//@available(iOS 16.4, macOS 13.3, tvOS 16.4, watchOS 9.4, *)
//struct MemberView_Previews: PreviewProvider {
//    static var previews: some View {
//        let viewModel = ParticipantsViewModel()
//        List {
//            MembersTabView()
//        }
//        .listStyle(.plain)
//        .environmentObject(viewModel)
//    }
//}

//
//struct AddParticipantButton: View {
//    @State var presentSheet: Bool = false
//    let conversation: Conversation?
//
//    var body: some View {
//        if conversation?.group == true, conversation?.admin == true{
//            Button {
//                presentSheet.toggle()
//            } label: {
//                HStack(spacing: 24) {
//                    Image(systemName: "person.badge.plus")
//                        .resizable()
//                        .scaledToFit()
//                        .frame(width: 24, height: 16)
//                        .foregroundStyle(Color.App.accent)
//                    Text("Thread.invite")
//                        .font(.fBody)
//                    Spacer()
//                }
//                .foregroundStyle(Color.App.accent)
//                .padding(EdgeInsets(top: 16, leading: 24, bottom: 16, trailing: 24))
//            }
//            .sheet(isPresented: $presentSheet) {
//                AddParticipantsToThreadView() { contacts in
//                    addParticipantsToThread(contacts)
//                    presentSheet.toggle()
//                }
//                .environment(\.layoutDirection, Language.isRTL ? .rightToLeft : .leftToRight)
//            }
//        }
//    }
//
//    public func addParticipantsToThread(_ contacts: ContiguousArray<Contact>) {
//        if conversation?.type?.isPrivate == true, conversation?.group == true {
//            AppState.shared.objectsContainer.appOverlayVM.dialogView = AnyView(
//                AdminLimitHistoryTimeDialog(threadId: conversation?.id ?? -1) { historyTime in
//                    if let historyTime = historyTime {
//                        add(contacts, historyTime)
//                    } else {
//                        add(contacts)
//                    }
//                }
//                    .environmentObject(AppState.shared.objectsContainer)
//            )
//        } else {
//            add(contacts)
//        }
//    }
//
//    private func add(_ contacts: ContiguousArray<Contact>, _ historyTime: UInt? = nil) {
//        guard let threadId = conversation?.id else { return }
//        let invitees: [Invitee] = contacts.compactMap{ .init(id: $0.user?.username, idType: .username, historyTime: historyTime) }
//        let req = AddParticipantRequest(invitees: invitees, threadId: threadId)
//        Task { @ChatGlobalActor in
//            ChatManager.activeInstance?.conversation.participant.add(req)
//        }
//    }
//}
//
