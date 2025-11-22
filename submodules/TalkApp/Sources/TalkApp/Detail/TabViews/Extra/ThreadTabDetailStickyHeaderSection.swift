//
//  ThreadTabDetailStickyHeaderSection.swift
//  Talk
//
//  Created by hamed on 1/29/24.
//

import Foundation
import SwiftUI
import TalkViewModels
import TalkUI

public struct ThreadTabDetailStickyHeaderSection: View {
    let header: String
    let height: CGFloat?
    @State private var width = ThreadViewModel.threadWidth

    public init(header: String, height: CGFloat? = nil) {
        self.header = header
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
        .padding(.horizontal, 16)
        .background(Color.App.dividerPrimary)
        .listRowBackground(Color.App.dividerPrimary)
        .background(frameReader)
    }

    private var frameReader: some View {
        GeometryReader { reader in
            Color.clear.onAppear {
                DispatchQueue.main.async {
                    width = reader.size.width
                }
            }
        }
    }
}
