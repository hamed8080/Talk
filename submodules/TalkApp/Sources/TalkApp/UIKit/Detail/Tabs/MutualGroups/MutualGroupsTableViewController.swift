//
//  MutualGroupsTableViewController.swift
//  Talk
//
//  Created by Hamed Hosseini on 9/23/21.
//

import Foundation
import UIKit
import Chat
import SwiftUI
import TalkViewModels

class MutualGroupsTableViewController: UIViewController, TabControllerDelegate {
    var dataSource: UITableViewDiffableDataSource<MutualGroupsListSection, MutualGroupItem>!
    var tableView: UITableView = UITableView(frame: .zero)
    let viewModel: MutualGroupViewModel
    
    weak var detailVM: ThreadDetailViewModel?
    public weak var scrollDelegate: UIChildViewScrollDelegate?
    public weak var onSelectDelegate: TabRowItemOnSelectDelegate?
    
    init(viewModel: MutualGroupViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        viewModel.delegate = self
        tableView.contentInset = .init(top: 0, left: 0, bottom: 128, right: 0)
        tableView.scrollIndicatorInsets = tableView.contentInset
        tableView.register(MutualCell.self, forCellReuseIdentifier: MutualCell.identifier)
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
        tableView.rowHeight = 96
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
        viewModel.fetchMutualThreads()
    }
}

extension MutualGroupsTableViewController: UIViewControllerScrollDelegate {
    func getInternalScrollView() -> UIScrollView {
        return tableView
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        scrollDelegate?.onChildViewDidScrolled(scrollView)
    }
}

extension MutualGroupsTableViewController {
    
    private func configureDataSource() {
        dataSource = UITableViewDiffableDataSource(tableView: tableView) { [weak self] (tableView, indexPath, item) -> UITableViewCell? in
            guard let self = self else { return nil }
            
            switch item {
            case .conversation(let conversation):
                let cell = tableView.dequeueReusableCell(
                    withIdentifier: MutualCell.identifier,
                    for: indexPath
                ) as? MutualCell
                
                // Set properties
                cell?.setConversation(conversation: conversation)
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

extension MutualGroupsTableViewController: UIMutualGroupsViewControllerDelegate {
   
    func apply(snapshot: NSDiffableDataSourceSnapshot<MutualGroupsListSection, MutualGroupItem>, animatingDifferences: Bool) {
        dataSource.apply(snapshot, animatingDifferences: animatingDifferences)
    }
    
    func updateImage(image: UIImage?, id: Int) {
        cell(id: id)?.setImage(image)
    }
    
    private func cell(id: Int) -> MutualCell? {
        guard let index = viewModel.mutualThreads.firstIndex(where: { $0.id == id }) else { return nil }
        return tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? MutualCell
    }
}

extension MutualGroupsTableViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
        if case .conversation(let conversation) = item {
            onSelectDelegate?.onSelectMutualGroup(conversation: conversation.toStruct())
            dismiss(animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let conversation = dataSource.itemIdentifier(for: indexPath),
              indexPath.row >= viewModel.mutualThreads.count - 10
        else { return }
        Task {
            try await viewModel.loadMoreMutualGroups()
        }
    }
}

//
//struct MutualsTabView: View {
//    @EnvironmentObject var viewModel: MutualGroupViewModel
//
//    var body: some View {
//        LazyVStack {
//            ThreadTabDetailStickyHeaderSection(header: "", height:  4)
//            if !viewModel.mutualThreads.isEmpty {
//                ForEach(viewModel.mutualThreads) { thread in
//                    MutualThreadRow(thread: thread)
//                        .padding(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 0))
//                        .onAppear {
//                            if thread.id == viewModel.mutualThreads.last?.id {
//                                Task {
//                                    await viewModel.loadMoreMutualGroups()
//                                }
//                            }
//                        }
//                        .onTapGesture {
//                            Task {
//                                try await goToConversation(thread)
//                            }
//                        }
//                }
//            }
//
//            if viewModel.lazyList.isLoading {
//                LoadingView()
//                    .id(UUID())
//                    .frame(width: 22, height: 22)
//            }
//
//            if viewModel.mutualThreads.isEmpty && !viewModel.lazyList.isLoading {
//                EmptyResultViewInTabs()
//            }
//        }
//    }
//    
//    /// We have to refetch the conversation because it is not a complete instance of Conversation in mutual response.
//    /// So things like admin, public link, and ... don't have any values.
//    private func goToConversation(_ conversation: Conversation) async throws {
//      
//        guard
//            let id = conversation.id,
//            let serverConversation = try await GetThreadsReuqester().get(.init(threadIds: [id])).first
//        else { return }
//        AppState.shared.objectsContainer.navVM.createAndAppend(conversation: serverConversation)
//    }
//}
//
//struct MutualThreadRow: View {
//    var thread: Conversation
//
//    init(thread: Conversation) {
//        self.thread = thread
//    }
//
//    var body: some View {
//        HStack {
//            ImageLoaderView(conversation: thread)
//                .id("\(thread.computedImageURL ?? "")\(thread.id ?? 0)")
//                .font(.fSubtitle)
//                .foregroundColor(.white)
//                .frame(width: 36, height: 36)
//                .background(Color(uiColor: String.getMaterialColorByCharCode(str: thread.title ?? "")))
//                .clipShape(RoundedRectangle(cornerRadius:(18)))
//            Text(thread.computedTitle)
//                .font(.fSubheadline)
//                .lineLimit(1)
//            Spacer()
//        }
//        .contentShape(Rectangle())
//        .padding(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
//    }
//}
//
//struct MutualThreadsView_Previews: PreviewProvider {
//    static var previews: some View {
//        MutualsTabView()
//    }
//}
