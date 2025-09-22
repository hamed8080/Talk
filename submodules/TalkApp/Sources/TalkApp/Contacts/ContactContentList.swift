//
//  ContactContentList.swift
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

struct ContactContentList: View {
    @EnvironmentObject var viewModel: ContactsViewModel
    @State private var type: StrictThreadTypeCreation = .p2p
    @State private var showBuilder = false
    @EnvironmentObject var builderVM: ConversationBuilderViewModel

    var body: some View {
        ContactsViewControllerWrapper(viewModel: viewModel)
//        swiftUIView
    }
    
    var swiftUIView: some View {
        List {
            totalContactCountView
            syncView
                .sandboxLabel()
            creationButtons
            if viewModel.searchedContacts.count > 0 || !viewModel.searchContactString.isEmpty {
                searchViews
            } else {
                normalStateContacts
            }
        }
        .listEmptyBackgroundColor(show: viewModel.contacts.isEmpty)
        .environment(\.defaultMinListRowHeight, 0)
        .animation(.easeInOut, value: viewModel.contacts)
        .animation(.easeInOut, value: viewModel.searchedContacts)
        .animation(.easeInOut, value: viewModel.lazyList.isLoading)
        .listStyle(.plain)
        .gesture(dragToHideKeyboardGesture)
        .safeAreaInset(edge: .top, spacing: 0) {
            ContactListToolbar()
        }
        .sheet(isPresented: $viewModel.showAddOrEditContactSheet, onDismiss: onAddOrEditDisappeared) {
            if #available(iOS 16.4, macOS 13.3, tvOS 16.4, watchOS 9.4, *) {
                AddOrEditContactView()
                    .environment(\.layoutDirection, Language.isRTL ? .rightToLeft : .leftToRight)
                    .environmentObject(viewModel)
                    .onDisappear {
                        onAddOrEditDisappeared()
                    }
            }
        }
        .onReceive(builderVM.$dismiss) { newValue in
            if newValue == true {
                showBuilder = false
            }
        }
        .sheet(isPresented: $showBuilder, onDismiss: onDismissBuilder){
            ConversationBuilder()
                .environment(\.layoutDirection, Language.isRTL ? .rightToLeft : .leftToRight)
                .environmentObject(builderVM)
                .onAppear {
                    Task {
                        await builderVM.show(type: type)
                    }
                }
        }
    }

    private func onDismissBuilder() {
        Task {
            await builderVM.clear()
        }
    }

    private var dragToHideKeyboardGesture: some Gesture {
        DragGesture()
            .onChanged{ _ in
                hideKeyboard()
            }
    }

    @ViewBuilder
    private var searchViews: some View {
        StickyHeaderSection(header: "Contacts.searched")
            .listRowInsets(.zero)
        ForEach(viewModel.searchedContacts) { contact in
            ContactRowContainer(contact: .constant(contact), isSearchRow: true, enableSwipeAction: false)
                .id("SEARCH-ROW-IN-CONTACT-LIST\(contact.id ?? -1)")
                .environment(\.showInviteButton, true)
        }
        .padding()
        ListLoadingView(isLoading: $viewModel.lazyList.isLoading)
            .id(UUID())
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .listRowInsets(.zero)
    }

    @ViewBuilder
    private var normalStateContacts: some View {
        ForEach(viewModel.contacts) { contact in
            ContactRowContainer(contact: .constant(contact), isSearchRow: false)
                .id("NORMAL-ROW-IN-CONTACT-LIST\(contact.id ?? -1)")
                .environment(\.showInviteButton, true)
        }
        .padding()
        .listRowInsets(.zero)
        ListLoadingView(isLoading: $viewModel.lazyList.isLoading)
            .id(UUID())
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .listRowInsets(.zero)
    }

    @ViewBuilder
    private var creationButtons: some View {
        Button {
            type = .privateGroup
            showBuilder.toggle()
        } label: {
            Label("Contacts.createGroup".bundleLocalized(), systemImage: "person.2")
                .foregroundStyle(Color.App.accent)
        }
        .listRowBackground(Color.App.bgPrimary)
        .listRowSeparatorTint(Color.App.dividerPrimary)

        Button {
            type = .privateChannel
            showBuilder.toggle()
        } label: {
            Label("Contacts.createChannel".bundleLocalized(), systemImage: "megaphone")
                .foregroundStyle(Color.App.accent)
        }
        .listRowBackground(Color.App.bgPrimary)
        .listRowSeparatorTint(Color.App.dividerPrimary)

        Button {
            viewModel.showAddOrEditContactSheet.toggle()
            viewModel.animateObjectWillChange()
        } label: {
            Label("Contacts.addContact".bundleLocalized(), systemImage: "person.badge.plus")
                .foregroundStyle(Color.App.accent)
        }
        .listRowBackground(Color.App.bgPrimary)
        .listRowSeparator(.hidden)
    }

    @ViewBuilder
    private var syncView: some View {
        if EnvironmentValues.isTalkTest {
            SyncView()
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
        }
    }

    @ViewBuilder
    private var totalContactCountView: some View {
        if viewModel.maxContactsCountInServer > 0, EnvironmentValues.isTalkTest {
            HStack(spacing: 4) {
                Spacer()
                Text("Contacts.total")
                    .font(.fBody)
                    .foregroundColor(.gray)
                Text("\(viewModel.maxContactsCountInServer)")
                    .font(.fBoldBody)
                Spacer()
            }
            .listRowBackground(Color.clear)
            .noSeparators()
            .sandboxLabel()
        }
    }

    private func onAddOrEditDisappeared() {
        /// Clearing the view for when the user cancels the sheet by dropping it down.
        viewModel.successAdded = false
        viewModel.showAddOrEditContactSheet = false
        viewModel.addContact = nil
        viewModel.editContact = nil
    }
}

struct ContactRowContainer: View {
    @Binding var contact: Contact
    @EnvironmentObject var viewModel: ContactsViewModel
    let isSearchRow: Bool
    var enableSwipeAction = true
    var separatorColor: Color {
        if !isSearchRow {
           return viewModel.contacts.last == contact ? Color.clear : Color.App.dividerPrimary
        } else {
            return viewModel.searchedContacts.last == contact ? Color.clear : Color.App.dividerPrimary
        }
    }

    var body: some View {
        ContactRow(contact: contact, isInSelectionMode: $viewModel.isInSelectionMode, isInSearchMode: isSearchRow)
            .animation(.spring(), value: viewModel.isInSelectionMode)
            .listRowBackground(Color.App.bgPrimary)
            .listRowSeparatorTint(separatorColor)
            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                if !enableSwipeAction {
                    EmptyView()
                } else if !viewModel.isInSelectionMode {
                    Button {
                        viewModel.editContact = contact
                        viewModel.showAddOrEditContactSheet.toggle()
                        viewModel.animateObjectWillChange()
                    } label: {
                        Label("General.edit", systemImage: "pencil")
                    }
                    .tint(Color.App.textSecondary)

                    let isBlocked = contact.blocked == true
                    Button {
                        if isBlocked, let contactId = contact.id {
                            viewModel.unblockWith(contactId)
                        } else {
                            viewModel.block(contact)
                        }
                    } label: {
                        Label(isBlocked ? "General.unblock" : "General.block", systemImage: isBlocked ? "hand.raised.slash.fill" : "hand.raised.fill")
                    }
                    .tint(Color.App.red)

                    Button {
                        viewModel.addToSelctedContacts(contact)
                        AppState.shared.objectsContainer.appOverlayVM.dialogView = AnyView(
                            DeleteContactView()
                                .environmentObject(viewModel)
                                .onDisappear {
                                    viewModel.removeToSelctedContacts(contact)
                                }
                        )
                    } label: {
                        Label("General.delete", systemImage: "trash")
                    }
                    .tint(.red)
                }
            }
            .onAppear {
                Task {
                    await viewModel.loadMore(id: contact.id)
                }
            }
            .onTapGesture {
                if viewModel.isInSelectionMode {
                    viewModel.toggleSelectedContact(contact: contact)
                } else if contact.hasUser == true {
                    Task {
                        try await AppState.shared.objectsContainer.navVM.openThread(contact: contact)
                    }
                }
            }
    }
}

class ContactTableViewController: UIViewController {
    var dataSource: UITableViewDiffableDataSource<ContactListSection, Contact>!
    var tableView: UITableView = UITableView(frame: .zero)
    let viewModel: ContactsViewModel
    static let resuableIdentifier = "CONTACTROW"
    
    init(viewModel: ContactsViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        viewModel.delegate = self
        tableView.register(ContactCell.self, forCellReuseIdentifier: ContactTableViewController.resuableIdentifier)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.rowHeight = 96
        tableView.delegate = self
        tableView.allowsMultipleSelection = false
        tableView.backgroundColor = Color.App.bgPrimaryUIColor
        tableView.separatorStyle = .none
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
        configureDataSource()
    }
}

extension ContactTableViewController {
    
    private func configureDataSource() {
        dataSource = UITableViewDiffableDataSource(tableView: tableView) { [weak self] (tableView, indexPath, contact) -> UITableViewCell? in
            guard let self = self else { return nil }
            let cell = tableView.dequeueReusableCell(
                withIdentifier: ContactTableViewController.resuableIdentifier,
                for: indexPath
            ) as? ContactCell
            
            // Set properties
            cell?.setContact(contact: contact, viewModel: viewModel)
            
            return cell
        }
    }
}

extension ContactTableViewController: UIContactsViewControllerDelegate {
    func updateUI() {
        /// Create
        var snapshot = NSDiffableDataSourceSnapshot<ContactListSection, Contact>()
        
        /// Configure
        snapshot.appendSections([.main])
        snapshot.appendItems(Array(viewModel.contacts), toSection: .main)
        
        /// Apply
        dataSource.apply(snapshot)
    }
    
    func updateImage(image: UIImage?, id: Int) {
        if let index = viewModel.contacts.firstIndex(where: { $0.id == id }),
           let cell = tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? ContactCell {
            cell.setImage(image)
        }
    }
}

extension ContactTableViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let contact = dataSource.itemIdentifier(for: indexPath) else { return }
        if viewModel.isInSelectionMode {
            viewModel.toggleSelectedContact(contact: contact)
        } else {
            Task {
                try await AppState.shared.objectsContainer.navVM.openThread(contact: contact)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "") { [weak self] action, view, success in

            self?.onSwipeDelete(indexPath)
            success(true)
        }
        deleteAction.image = UIImage(systemName: "trash")
        deleteAction.backgroundColor = UIColor.red
        
        let editAction = UIContextualAction(style: .normal, title: "") { [weak self] action, view, success in
            self?.onSwipeEdit(indexPath)
            success(true)
        }
        editAction.image = UIImage(systemName: "pencil")
        editAction.backgroundColor = UIColor.gray
        
        let isBlocked = dataSource.itemIdentifier(for: indexPath)?.blocked == true
        let blockAction = UIContextualAction(style: .normal, title: "") { [weak self] action, view, success in
            self?.onSwipeBlock(indexPath)
            success(true)
        }
        blockAction.image = UIImage(systemName: isBlocked ? "hand.raised.slash.fill" : "hand.raised.fill")
        blockAction.backgroundColor = UIColor.darkGray
        
        let config = UISwipeActionsConfiguration(actions: [editAction, blockAction, deleteAction])
        return config
    }
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let contact = dataSource.itemIdentifier(for: indexPath) else { return }
        viewModel.loadMore(id: contact.id)
    }
}

extension ContactTableViewController {
    func onSwipeDelete(_ indexPath: IndexPath) {
        guard let contact = dataSource.itemIdentifier(for: indexPath) else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred(intensity: 1)
        viewModel.addToSelctedContacts(contact)
        AppState.shared.objectsContainer.appOverlayVM.dialogView = AnyView(
            DeleteContactView()
                .environmentObject(viewModel)
                .onDisappear {
                    self.viewModel.removeToSelctedContacts(contact)
                }
        )
    }
    
    func onSwipeEdit(_ indexPath: IndexPath) {
        guard let contact = dataSource.itemIdentifier(for: indexPath) else { return }
        viewModel.editContact = contact
        
        if #available(iOS 16.4, *) {
            let rootView = AddOrEditContactView()
                .environment(\.layoutDirection, Language.isRTL ? .rightToLeft : .leftToRight)
                .environmentObject(viewModel)
                .onDisappear { [weak self] in
                    guard let self = self else { return }
                    /// Clearing the view for when the user cancels the sheet by dropping it down.
                    viewModel.successAdded = false
                    viewModel.addContact = nil
                    viewModel.editContact = nil
                }
            var sheetVC = UIHostingController(rootView: rootView)
            sheetVC.modalPresentationStyle = .formSheet
            self.present(sheetVC, animated: true)
        }
    }
    
    func onSwipeBlock(_ indexPath: IndexPath) {
        guard let contact = dataSource.itemIdentifier(for: indexPath) else { return }
        if contact.blocked == true, let contactId = contact.id {
            viewModel.unblockWith(contactId)
        } else {
            viewModel.block(contact)
        }
    }
}

class ContactCell: UITableViewCell {
    private let titleLabel = UILabel()
    private let notFoundLabel = UILabel()
    private let inviteButton = UIButton()
    private let blockedLable = UILabel()
    private let radio = SelectMessageRadio()
    private let avatar = UIImageView(frame: .zero)
    private let avatarInitialLable = UILabel()
    private var radioIsHidden = true
    private var showInvite = false

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureView() {
        /// Background color once is selected or tapped
        selectionStyle = .none
        
        semanticContentAttribute = Language.isRTL ? .forceRightToLeft : .forceLeftToRight
        contentView.semanticContentAttribute = Language.isRTL ? .forceRightToLeft : .forceLeftToRight
        translatesAutoresizingMaskIntoConstraints = true
        contentView.backgroundColor = .clear
        backgroundColor = .clear
        
        /// Full name lable
        titleLabel.font = UIFont.fSubheadline
        titleLabel.textColor = Color.App.textPrimaryUIColor
        titleLabel.textAlignment = .center
        titleLabel.accessibilityIdentifier = "ContactCell.titleLable"
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.textAlignment = Language.isRTL ? .right : .left
        titleLabel.numberOfLines = 1
        contentView.addSubview(titleLabel)
        
        /// Not found label
        notFoundLabel.font = UIFont.fCaption2
        notFoundLabel.textColor = Color.App.accentUIColor
        notFoundLabel.textAlignment = .center
        notFoundLabel.text = "Contctas.list.notFound".bundleLocalized()
        notFoundLabel.accessibilityIdentifier = "ContactCell.notFoundLabel"
        notFoundLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(notFoundLabel)
        
        /// Invite button
        inviteButton.titleLabel?.font = UIFont.fCaption2
        inviteButton.setTitleColor(Color.App.whiteUIColor, for: .normal)
        inviteButton.setTitle("Contacts.invite".bundleLocalized(), for: .normal)
        inviteButton.accessibilityIdentifier = "ContactCell.inviteButton"
        inviteButton.translatesAutoresizingMaskIntoConstraints = false
        inviteButton.layer.backgroundColor = Color.App.accentUIColor?.cgColor
        inviteButton.layer.cornerRadius = 16
        contentView.addSubview(inviteButton)
        
        /// Block label
        blockedLable.font = UIFont.fCaption2
        blockedLable.textColor = Color.App.redUIColor
        blockedLable.textAlignment = .center
        blockedLable.text = "General.blocked".bundleLocalized()
        blockedLable.accessibilityIdentifier = "ContactCell.blockedLable"
        blockedLable.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(blockedLable)
        
        /// Selection radio
        radio.accessibilityIdentifier = "ContactCell.radio"
        radio.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(radio)
        
        /// Avatar or user name abbrevation
        avatar.accessibilityIdentifier = "ContactCell.avatar"
        avatar.translatesAutoresizingMaskIntoConstraints = false
        avatar.layer.cornerRadius = 22
        avatar.layer.masksToBounds = true
        contentView.addSubview(avatar)
        
        avatarInitialLable.accessibilityIdentifier = "ContactCell.avatarInitialLable"
        avatarInitialLable.translatesAutoresizingMaskIntoConstraints = false
        avatarInitialLable.layer.cornerRadius = 22
        avatarInitialLable.layer.masksToBounds = true
        avatarInitialLable.textAlignment = .center
        avatarInitialLable.font = UIFont.fBoldBody
        
        contentView.addSubview(avatarInitialLable)
        
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 30),
            
            radio.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            radio.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            
            avatar.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            avatar.leadingAnchor.constraint(equalTo: radio.trailingAnchor, constant: 8),
            avatar.widthAnchor.constraint(equalToConstant: 52),
            avatar.heightAnchor.constraint(equalToConstant: 52),
            
            avatarInitialLable.centerYAnchor.constraint(equalTo: avatar.centerYAnchor),
            avatarInitialLable.centerXAnchor.constraint(equalTo: avatar.centerXAnchor),
            avatarInitialLable.widthAnchor.constraint(equalToConstant: 52),
            avatarInitialLable.heightAnchor.constraint(equalToConstant: 52),
            
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: avatar.trailingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: notFoundLabel.leadingAnchor, constant: 16),
            
            notFoundLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            notFoundLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            
            inviteButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            inviteButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            inviteButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 64)
        ])
        
        if radioIsHidden {
            radio.widthAnchor.constraint(equalToConstant: 0).isActive = true
            radio.heightAnchor.constraint(equalToConstant: 0).isActive = true
            radio.isHidden = true
        }
        
        notFoundLabel.isHidden = true
        blockedLable.isHidden = true
        inviteButton.isHidden = true
    }
    
    public func setContact(contact: Contact, viewModel: ContactsViewModel) {
        titleLabel.text = "\(contact.firstName ?? "") \(contact.lastName ?? "")"
        
        if contact.blocked == true {
            blockedLable.isHidden = false
        }
        
        notFoundLabel.isHidden = contact.hasUser == true
        if contact.hasUser == false || contact.hasUser == nil, showInvite {
            inviteButton.isHidden = false
        }
        
        let contactName = "\(contact.firstName ?? "") \(contact.lastName ?? "")"
        let isEmptyContactString = contactName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let name = !isEmptyContactString ? contactName : contact.user?.name
        
        avatar.backgroundColor = String.getMaterialColorByCharCode(str: name ?? "")
        avatarInitialLable.text = String.splitedCharacter(name ?? "")
        if let vm = viewModel.imageLoader(for: contact.id ?? -1) {
            avatar.image = vm.image
            avatarInitialLable.isHidden = vm.isImageReady
        } else {
            avatarInitialLable.isHidden = false
        }
    }
    
    public func setImage(_ image: UIImage?) {
        avatar.image = image
        avatarInitialLable.isHidden = image != nil
    }
}

struct ContactsViewControllerWrapper: UIViewControllerRepresentable {
    let viewModel: ContactsViewModel
    
    func makeUIViewController(context: Context) -> some UIViewController {
        let vc = ContactTableViewController(viewModel: viewModel)
        return vc
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) { }
}

struct ContactContentList_Previews: PreviewProvider {
    static var previews: some View {
        let vm = ContactsViewModel()
        ContactContentList()
            .environmentObject(vm)
            .environmentObject(AppState.shared)
    }
}
