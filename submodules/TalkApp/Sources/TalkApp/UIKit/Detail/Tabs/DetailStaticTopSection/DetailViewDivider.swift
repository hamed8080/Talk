//
//  DetailViewDivider.swift
//  TalkApp
//
//  Created by Hamed Hosseini on 1/3/26.
//

import UIKit
import SwiftUI
import TalkUI

final class DetailViewDivider: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureView() {
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = Color.App.bgSecondaryUIColor
    }
}
