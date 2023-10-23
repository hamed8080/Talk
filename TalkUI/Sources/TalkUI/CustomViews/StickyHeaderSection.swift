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

    public init(header: String, height: CGFloat? = nil) {
        self.header = header
        self.height = height
    }

    public var body: some View {
        HStack {
            Text(String(localized: .init(header)))
                .foregroundColor(Color.hint)
                .font(.iransansCaption)
            Spacer()
        }
        .frame(height: height)
        .frame(minWidth: 0, maxWidth: .infinity)
        .padding(.horizontal, 16)
        .background(Color.bgSpaceItem)
        .listRowBackground(Color.bgSpaceItem)
    }
}

struct StickyHeaderSection_Previews: PreviewProvider {
    static var previews: some View {
        StickyHeaderSection(header: "TEST")
    }
}
