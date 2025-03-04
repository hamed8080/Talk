//
//  DetailLoading.swift
//  Talk
//
//  Created by hamed on 10/30/23.
//

import SwiftUI
import TalkViewModels
import TalkUI

struct DetailLoading: View {
    @EnvironmentObject var viewModel: DetailTabDownloaderViewModel

    var body: some View {
        if viewModel.isLoading {
            HStack {
                Spacer()
                LoadingView()
                    .id(UUID())
                    .frame(width: 22, height: 22)
                Spacer()
            }
            .padding()
        }
    }
}

struct DetailLoading_Previews: PreviewProvider {
    static var previews: some View {
        DetailLoading()
    }
}
