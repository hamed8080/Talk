//
//  RecordingDotView.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import SwiftUI

struct RecordingDotView: View {
    @EnvironmentObject var callState: CallViewModel
    @EnvironmentObject var recordingViewModel: RecordingViewModel
    @State var showRecordingIndicator: Bool = false

    var body: some View {
        Image(systemName: "record.circle")
            .resizable()
            .frame(width: 16, height: 16)
            .foregroundColor(Color.red)
            .position(x: 32, y: 24)
            .opacity(showRecordingIndicator ? 1 : 0)
            .animation(.easeInOut, value: showRecordingIndicator)
            .onAppear {
                Timer.scheduledTimer(withTimeInterval: showRecordingIndicator ? 0.7 : 1, repeats: true) { _ in
                    Task { @MainActor in
                        showRecordingIndicator.toggle()
                    }
                }
            }
    }
}
