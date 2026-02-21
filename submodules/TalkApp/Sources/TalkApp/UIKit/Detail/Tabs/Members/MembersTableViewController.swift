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

class MembersTableViewController: UIViewController, TabControllerDelegate {
    var dataSource: UITableViewDiffableDataSource<MembersListSection, MemberItem>!
    var tableView: UITableView = UITableView(frame: .zero)
    let viewModel: ParticipantsViewModel
    
    private var contextMenuContainer: ContextMenuContainerView?
    
    weak var detailVM: ThreadDetailViewModel?
    public weak var scrollDelegate: UIChildViewScrollDelegate?
    public weak var onSelectDelegate: TabRowItemOnSelectDelegate?
    
    init(viewModel: ParticipantsViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        viewModel.delegate = self
        tableView.contentInset = .init(top: 0, left: 0, bottom: 128, right: 0)
        tableView.scrollIndicatorInsets = tableView.contentInset
        tableView.register(MemberSearchTextFieldCell.self, forCellReuseIdentifier: MemberSearchTextFieldCell.identifier)
        tableView.register(MemberAddParticipantButtonCell.self, forCellReuseIdentifier: MemberAddParticipantButtonCell.identifier)
        tableView.register(MemberCell.self, forCellReuseIdentifier: MemberCell.identifier)
        tableView.register(NothingFoundCell.self, forCellReuseIdentifier: NothingFoundCell.identifier)
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
        contextMenuContainer = .init(delegate: self, vc: parentVC)
        if viewModel.participants.count == 0 {
            Task {
                await viewModel.getParticipants()
            }
        }
    }
}

extension MembersTableViewController: UIViewControllerScrollDelegate {
    func getInternalScrollView() -> UIScrollView {
        return tableView
    }
    
    func setBottomInset(_ inset: CGFloat) {
        tableView.contentInset.bottom = inset
    }
}

extension MembersTableViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        scrollDelegate?.onChildViewDidScrolled(scrollView)
    }
}

extension MembersTableViewController {
    
    private func configureDataSource() {
        dataSource = UITableViewDiffableDataSource(tableView: tableView) { [weak self] (tableView, indexPath, item) -> UITableViewCell? in
            guard let self = self else { return nil }
            switch item {
            case .searchTextFields:
                let cell = tableView.dequeueReusableCell(
                    withIdentifier: MemberSearchTextFieldCell.identifier,
                    for: indexPath
                ) as? MemberSearchTextFieldCell
                cell?.viewModel = viewModel
                return cell
            case .addParticipantButton:
                let cell = tableView.dequeueReusableCell(
                    withIdentifier: MemberAddParticipantButtonCell.identifier,
                    for: indexPath
                ) as? MemberAddParticipantButtonCell
                cell?.conversation = viewModel.thread
                return cell
            case .item(let item):
                let cell = tableView.dequeueReusableCell(
                    withIdentifier: MemberCell.identifier,
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
                    withIdentifier: NothingFoundCell.identifier,
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
        /// Reject calling load more for add participant button or search text field
        /// There is no way to fetch indexPath.row == 1 loadMore
        let section = indexPath.section
        let isAdmin = viewModel.thread?.admin == true
        let isGroup = viewModel.thread?.group == true
        let isAddButton = section == MembersListSection.addParticipantButton.rawValue
        let isSearchField = section == MembersListSection.searchTextFields.rawValue
        if isAdmin && isGroup && (isAddButton || isSearchField) {
            return
        }
        guard
            let conversation = dataSource.itemIdentifier(for: indexPath),
            indexPath.row >= viewModel.participants.count - 10
        else { return }
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
    
    private var parentVC: UIViewController {
        return AppState.shared.objectsContainer.navVM.splitVC ?? self
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
