//
//  TabDetailsText.swift
//  TalkApp
//
//  Created by Hamed Hosseini on 7/10/25.
//

import SwiftUI
import TalkViewModels

struct TabDetailsText: View {
    let rowModel: TabRowModel
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(rowModel.fileName)
                .font(Font.normal(.body))
                .foregroundStyle(Color.App.textPrimary)
                .lineLimit(1)
                .truncationMode(.middle)
            HStack {
                Text(rowModel.time)
                    .foregroundColor(Color.App.textSecondary)
                    .font(Font.normal(.caption2))
                Spacer()
                Text(rowModel.fileSizeString)
                    .foregroundColor(Color.App.textSecondary)
                    .font(Font.normal(.caption3))
            }
        }
    }
}
