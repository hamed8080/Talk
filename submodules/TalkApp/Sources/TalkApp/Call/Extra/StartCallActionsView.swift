//
//  StartCallActionsView.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import SwiftUI

/// When receive or start call to someone you will see this screen and it will show only if call is not started.
struct StartCallActionsView: View {
    @EnvironmentObject var viewModel: CallViewModel

    var body: some View {
        if viewModel.isCallStarted == false {
            VStack {
                Spacer()
                Text("\(viewModel.callTitle ?? "") \(viewModel.isReceiveCall ? "Ringing..." : "Calling...")")
                    .font(.title)
                    .fontWeight(.bold)

                HStack {
                    if viewModel.call?.type == .video {
                        Spacer()
                        CallControlItem(iconSfSymbolName: "video.fill", subtitle: "Answer", color: .green) {
                            viewModel.answerCall(video: true, audio: true)
                        }
                    }

                    Spacer()

                    CallControlItem(iconSfSymbolName: "phone.fill", subtitle: "Answer", color: .green) {
                        viewModel.answerCall(video: false, audio: true)
                    }

                    Spacer()

                    CallControlItem(iconSfSymbolName: "phone.down.fill", subtitle: "Reject Call", color: .red) {
                        viewModel.cancelCall()
                    }
                    Spacer()
                }
            }
        }
    }
}
