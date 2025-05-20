//
//  DetailViewNumberOfParticipants.swift
//  Talk
//
//  Created by hamed on 5/29/24.
//

import Foundation
import SwiftUI
import TalkViewModels
import TalkModels

struct DetailViewNumberOfParticipants: View {
    var viewModel: ThreadViewModel
    /// Even we don't use this detailVM variable it is essential to update participants count when a participant is removed / added ...
    @EnvironmentObject var detailVM: ThreadDetailViewModel

    var body: some View {
        let label = "Thread.Toolbar.participants".bundleLocalized()
        Text(verbatim: "\(countString ?? "") \(label)")
            .font(.fCaption3)
            .foregroundStyle(Color.App.textSecondary)
    }

    private var countString: String? {
        let count = viewModel.thread.participantCount
        return count?.localNumber(locale: Language.preferredLocale)
    }
}
