//
//  MoreControlsView.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import SwiftUI

struct MoreControlsView: View {
    @EnvironmentObject var viewModel: CallViewModel
    @EnvironmentObject var recordingViewModel: RecordingViewModel
    @Binding var showCallParticipants: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 32) {
                HStack {
                    CallControlItem(iconSfSymbolName: "record.circle", subtitle: "Record", color: .red, vertical: true) {
                        recordingViewModel.toggleRecording()
                    }

                    if recordingViewModel.isRecording {
                        Spacer()
                        Text(recordingViewModel.recordingTimerString ?? "")
                            .fontWeight(.medium)
                            .padding([.leading, .trailing], 16)
                            .padding([.top, .bottom], 8)
                            .background(
                                RoundedRectangle(cornerRadius: 5)
                                    .fill(.thinMaterial)
                            )
                    }
                }

                CallControlItem(iconSfSymbolName: "person.fill.badge.plus", subtitle: "prticipants", color: .gray, vertical: true) {
                    withAnimation {
                        showCallParticipants.toggle()
                    }
                }

                CallControlItem(iconSfSymbolName: "questionmark.app.fill", subtitle: "Update Participants Status", color: .blue, vertical: true) {
                    viewModel.callInquiry()
                }

                Spacer()
            }
            .padding()
            Spacer()
        }
    }
}
