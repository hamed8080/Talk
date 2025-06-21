//
//  MentionTableView.swift
//  Talk
//
//  Created by hamed on 3/13/23.
//

import SwiftUI
import TalkViewModels
import TalkUI
import TalkExtensions
import ChatModels

public final class MentionTableView: UITableView {
    private weak var threadVM: ThreadViewModel?
    private let cellIdentifier = String(describing: MentionCell.self)
    private var heightConstraint: NSLayoutConstraint!
    private var mentionList: ContiguousArray<Participant> { viewModel?.mentionList ?? .init() }
    private let cellHeight: CGFloat = 48
    private var viewModel: MentionListPickerViewModel? { threadVM?.mentionListPickerViewModel }

    public init(viewModel: ThreadViewModel?) {
        self.threadVM = viewModel
        super.init(frame: .zero, style: .plain)
        configureView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureView() {
        translatesAutoresizingMaskIntoConstraints = false
        register(MentionCell.self, forCellReuseIdentifier: cellIdentifier)
        delegate = self
        dataSource = self
        backgroundColor = .clear
        separatorStyle = .none
        rowHeight = 48

        let blurEffect = UIBlurEffect(style: .systemThinMaterial)
        let effectView = UIVisualEffectView(effect: blurEffect)
        effectView.accessibilityIdentifier = "effectViewMentionTableView"
        effectView.translatesAutoresizingMaskIntoConstraints = false
        backgroundView = effectView

        heightConstraint = heightAnchor.constraint(equalToConstant: 0)
        heightConstraint.identifier = "heightConstraintMentionTableView"

        NSLayoutConstraint.activate([
            heightConstraint,
            effectView.leadingAnchor.constraint(equalTo: leadingAnchor),
            effectView.trailingAnchor.constraint(equalTo: trailingAnchor),
            effectView.topAnchor.constraint(equalTo: topAnchor),
            effectView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])

        viewModel?.onImageParticipant = { [weak self] participant in
            guard let self = self else { return }
            if let index = mentionList.firstIndex(where: {$0.id == participant.id}) {
                reloadRows(at: [IndexPath(row: index, section: 0)], with: .fade)
            }
        }
    }

    public func updateMentionList(stack: UIStackView) {
        let show = mentionList.count > 0
        if !show {
            removeFromSuperview()
            UIView.animate(withDuration: 0.2) {
                self.alpha = 0.0
            }
        } else if superview == nil {
            stack.insertArrangedSubview(self, at: 0)
            alpha = 0.0
            UIView.animate(withDuration: 0.2) {
                self.alpha = 1.0
            }
        }
        let maxHeight = cellHeight * 4
        heightConstraint.constant = min(maxHeight, CGFloat(mentionList.count) * 48)
        reloadData()
    }
}

extension MentionTableView: UITableViewDelegate {
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let viewModel = viewModel, let threadVM = threadVM else { return }
        let participant = viewModel.mentionList[indexPath.row]
        threadVM.sendContainerViewModel.addMention(participant)
        threadVM.delegate?.onMentionListUpdated()
    }

    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return cellHeight
    }
}

extension MentionTableView: UITableViewDataSource {
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier) as? MentionCell
        guard let viewModel = viewModel,
              let threadVM = threadVM,
              let cell = cell
        else { return UITableViewCell() }
        let participant = viewModel.mentionList[indexPath.row]
        cell.setValues(threadVM, participant)
        return cell
    }

    public func numberOfSections(in tableView: UITableView) -> Int { 1 }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel?.mentionList.count ?? 0
    }
    
    public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row == viewModel?.mentionList.indices.last {
            Task {
                await viewModel?.loadMore()
            }
        }
    }
}
