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
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
        tableView.backgroundColor = .red
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
            cell?.setContact(contact: contact)
            
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
}

class ContactCell: UITableViewCell {
    private let titleLabel = UILabel()
    private let notFoundLabel = UILabel()
    private let inviteButton = UIButton()
    private let blockedLable = UILabel()
    private let radio = SelectMessageRadio()
    private let avatar = AvatarView(frame: .zero)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureView() {
        translatesAutoresizingMaskIntoConstraints = true
        
        /// Full name lable
        titleLabel.font = UIFont.fCaption
        titleLabel.textColor = Color.App.accentUIColor
        titleLabel.textAlignment = .center
        titleLabel.text = "Messages.unreadMessages".bundleLocalized()
        titleLabel.backgroundColor = Color.App.bgChatUserUIColor
        titleLabel.accessibilityIdentifier = "labelUnreadBubbleCell"
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)
        
        /// Not found label
        notFoundLabel.font = UIFont.fCaption
        notFoundLabel.textColor = Color.App.accentUIColor
        notFoundLabel.textAlignment = .center
        notFoundLabel.text = "Messages.unreadMessages".bundleLocalized()
        notFoundLabel.backgroundColor = Color.App.bgChatUserUIColor
        notFoundLabel.accessibilityIdentifier = "labelUnreadBubbleCell"
        notFoundLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(notFoundLabel)
        
        /// Invite button
//        inviteButton.font = UIFont.fCaption
//        inviteButton.textColor = Color.App.accentUIColor
//        inviteButton.textAlignment = .center
//        inviteButton.text = "Messages.unreadMessages".bundleLocalized()
        inviteButton.backgroundColor = Color.App.bgChatUserUIColor
        inviteButton.accessibilityIdentifier = "labelUnreadBubbleCell"
        inviteButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(inviteButton)
        
        /// Block label
        blockedLable.font = UIFont.fCaption
        blockedLable.textColor = Color.App.accentUIColor
        blockedLable.textAlignment = .center
        blockedLable.text = "Messages.unreadMessages".bundleLocalized()
        blockedLable.backgroundColor = Color.App.bgChatUserUIColor
        blockedLable.accessibilityIdentifier = "labelUnreadBubbleCell"
        blockedLable.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(blockedLable)
        
        /// Selection radio
//        radio.font = UIFont.fCaption
//        radio.textColor = Color.App.accentUIColor
//        radio.textAlignment = .center
//        radio.text = "Messages.unreadMessages".bundleLocalized()
        radio.backgroundColor = Color.App.bgChatUserUIColor
        radio.accessibilityIdentifier = "labelUnreadBubbleCell"
        radio.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(radio)
        
        /// Avatar or user name abbrevation
//        avatar.font = UIFont.fCaption
//        avatar.textColor = Color.App.accentUIColor
//        avatar.textAlignment = .center
//        avatar.text = "Messages.unreadMessages".bundleLocalized()
        avatar.backgroundColor = Color.App.bgChatUserUIColor
        avatar.accessibilityIdentifier = "labelUnreadBubbleCell"
        avatar.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(avatar)
        
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 30),
            
            titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
            
        ])
    }
    
    public func setContact(contact: Contact) {
        titleLabel.text = contact.firstName ?? ""
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
