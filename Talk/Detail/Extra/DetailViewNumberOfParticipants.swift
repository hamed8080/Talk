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

    var body: some View {
        let label = String(localized: .init("Thread.Toolbar.participants"), bundle: Language.preferedBundle)
        Text(verbatim: "\(countString ?? "") \(label)")
            .font(.fCaption3)
            .foregroundStyle(Color.App.textSecondary)
    }

    private var countString: String? {
        let count = viewModel.thread.participantCount
        return count?.localNumber(locale: Language.preferredLocale)
    }
}
