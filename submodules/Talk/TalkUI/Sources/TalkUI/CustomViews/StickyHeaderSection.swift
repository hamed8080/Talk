//
//  StickyHeaderSection.swift
//  TalkUI
//
//  Created by hamed on 2/20/22.
//

import SwiftUI

public struct StickyHeaderSection: View {
    let header: String
    let height: CGFloat?
    let horizontalPadding: CGFloat

    public init(header: String, height: CGFloat? = nil, horizontalPadding: CGFloat = 16) {
        self.header = header
        self.horizontalPadding = horizontalPadding
        self.height = height
    }

    public var body: some View {
        HStack {
            Text(header)
                .foregroundColor(Color.App.textSecondary)
                .font(Font.normal(.caption))
            Spacer()
        }
        .frame(height: height)
        .frame(minWidth: 0, maxWidth: .infinity)
        .padding(.horizontal, horizontalPadding)
        .background(Color.App.dividerPrimary)
        .listRowBackground(Color.App.dividerPrimary)
    }
}

struct StickyHeaderSection_Previews: PreviewProvider {
    static var previews: some View {
        StickyHeaderSection(header: "TEST")
    }
}
