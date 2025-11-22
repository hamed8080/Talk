//
//  DetailLoading.swift
//  Talk
//
//  Created by hamed on 10/30/23.
//

import SwiftUI
import TalkViewModels
import TalkUI
import Lottie

struct DetailLoading: View {
    @EnvironmentObject var viewModel: DetailTabDownloaderViewModel

    var body: some View {
        if viewModel.isLoading {
            HStack {
                Spacer()
                LottieView(animation: .named("talk_logo_animation.json"))
                    .id(UUID())
                    .frame(width: 52, height: 52)
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
