//
//  File.swift
//  
//
//  Created by hamed on 6/28/23.
//

import Foundation
import SwiftUI

@available(iOS 16.1, *)
public struct SectionTitleView: View {
    var title: String

    public init(title: String) {
        self.title = title
    }

    public var body: some View {
        Section {
            LinearGradient(gradient: Gradient(colors: [.orange, .purple]),
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
            .mask {
                Text(title)
                    .font(.fBoldTitle)
            }
        }
        .listRowBackground(Color.clear)
    }
}

@available(iOS 16.1, *)
public struct SectionImageView: View {
    var image: Image

    public init(image: Image) {
        self.image = image
    }

    public var body: some View {
        Section {
            HStack {
                Spacer()
                image
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 96, maxHeight: 96)
                    .scaledToFit()
                    .padding()
                Spacer()
            }
        }
        .listRowBackground(Color.clear)
    }
}
