//
//  SectionRowContainer.swift
//  Talk
//
//  Created by hamed on 5/6/24.
//

import SwiftUI

struct SectionRowContainer: View {
    let key: String
    let value: String
    let button: AnyView?
    let lineLimit: Int?

    init(key: String, value: String, lineLimit: Int? = 2, button: AnyView? = nil) {
        self.key = key
        self.value = value
        self.button = button
        self.lineLimit = lineLimit
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(key)
                    .font(.fCaption)
                    .foregroundStyle(Color.App.textSecondary)
                Text(value)
                    .font(.fBody)
                    .foregroundStyle(Color.App.textPrimary)
                    .lineLimit(lineLimit)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)
            }
            Spacer()
            button
        }
        .padding(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
    }
}

struct SectionRowContainer_Previews: PreviewProvider {
    static var previews: some View {
        SectionRowContainer(key: "", value: "")
    }
}
