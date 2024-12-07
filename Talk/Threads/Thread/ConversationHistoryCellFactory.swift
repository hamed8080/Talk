//
//  ConversationHistoryCellFactory.swift
//  Talk
//
//  Created by hamed on 3/18/24.
//

import Foundation
import UIKit
import TalkViewModels
import TalkModels
import ChatModels

@MainActor
public final class ConversationHistoryCellFactory {
    class func reuse(_ tableView: UITableView, _ indexPath: IndexPath, _ viewModel: ThreadViewModel?) -> UITableViewCell {
        guard let viewModel = viewModel?.historyVM.mSections.viewModelWith(indexPath) else {
            return UITableViewCell()
        }
        let identifier = viewModel.calMessage.rowType.cellType
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier.rawValue, for: indexPath)
        switch identifier {
        case .call:
            let cell = (cell as? CallEventCell) ?? CallEventCell()
            cell.setValues(viewModel: viewModel)
            return cell
        case .partnerMessage:
            let cell = cell as? PartnerMessageCell ?? .init()
            cell.setValues(viewModel: viewModel)
            return cell
        case .meMessage:
            let cell = cell as? MyselfMessageCell ?? .init()
            cell.setValues(viewModel: viewModel)
            return cell
        case .participants:
            let cell = (cell as? ParticipantsEventCell) ?? ParticipantsEventCell()
            cell.setValues(viewModel: viewModel)
            return cell
        case .unreadBanner:
            return UnreadBubbleCell()
        case .unknown:
            return UITableViewCell()
        }
    }

    public class func registerCellsAndHeader(_ tableView: UITableView) {
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: CellTypes.unknown.rawValue)
        tableView.register(PartnerMessageCell.self, forCellReuseIdentifier: CellTypes.partnerMessage.rawValue)
        tableView.register(MyselfMessageCell.self, forCellReuseIdentifier: CellTypes.meMessage.rawValue)
        tableView.register(CallEventCell.self, forCellReuseIdentifier: CellTypes.call.rawValue)
        tableView.register(ParticipantsEventCell.self, forCellReuseIdentifier: CellTypes.participants.rawValue)
        tableView.register(UnreadBubbleCell.self, forCellReuseIdentifier: CellTypes.unreadBanner.rawValue)

        // HEADER
        tableView.register(SectionHeaderView.self, forHeaderFooterViewReuseIdentifier: String(describing: SectionHeaderView.self))
    }
}
