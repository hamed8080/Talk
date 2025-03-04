//
//  PartnerMessageCell.swift
//  Talk
//
//  Created by hamed on 6/6/24.
//

import Foundation
import UIKit
import TalkModels

public final class PartnerMessageCell: MessageBaseCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
