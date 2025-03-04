//
//  LoadTestsView.swift
//  Talk
//
//  Created by hamed on 2/21/24.
//

import SwiftUI
import TalkUI
import TalkExtensions
import TalkModels

struct LoadTestsView: View {
    @State private var threadId = ""
    @State private var start = ""
    @State private var end = ""

    var body: some View {
        List {
            Section {
                VStack(spacing: 16) {
                    TextField("ThreadId".bundleLocalized(), text: $threadId)
                        .keyboardType(.numberPad)
                        .padding()
                        .applyAppTextfieldStyle(topPlaceholder: "ThreadId")
                    TextField("Start".bundleLocalized(), text: $start)
                        .keyboardType(.numberPad)
                        .padding()
                        .applyAppTextfieldStyle(topPlaceholder: "Start")
                    TextField("End".bundleLocalized(), text: $end)
                        .keyboardType(.numberPad)
                        .padding()
                        .applyAppTextfieldStyle(topPlaceholder: "End")
                }
            } header: {
                Text("Rapid Send")
            }
        }.safeAreaInset(edge: .bottom) {
            SubmitBottomButton(text: "Start rapid Send") {
                LoadTests.rapidSend(threadId: Int(threadId)!,
                                    messageTempelate: LoadTests.longMessage,
                                    start: Int(start)!,
                                    end: Int(end)!)
            }
        }
    }
}
