//
//  LogRow.swift
//  Talk
//
//  Created by hamed on 6/27/22.
//

import Chat
import Logger
import SwiftUI
import TalkUI

struct LogRow: View {
    @State private var logDate = ""
    var log: Log
    var color: Color {
        let type = log.type
        if type == .internalLog {
            return Color.App.accent
        } else if type == .received {
            return Color.App.red
        } else {
            return Color.App.color2
        }
    }

    static var formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .full
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSSSS"
        formatter.locale = Locale(identifier: "en_US")
        return formatter
    }()

    var body: some View {
        ZStack(alignment: .leading) {
            color.opacity(0.2)
            VStack (alignment: .leading){
                HStack {
                    Text(verbatim: "\(log.time?.millisecondsSince1970 ?? 0)")
                    Text(verbatim: logDate)
                }
                TextEditor(text: .constant(log.message ?? ""))
                    .frame(maxHeight: UIDevice.current.userInterfaceIdiom == .pad ? 420 : 320)
            }
            .padding()
        }
        .font( UIDevice.current.userInterfaceIdiom == .pad ? Font.normal(.body) : Font.normal(.caption))
        .environment(\.layoutDirection, .leftToRight)
        .overlay(alignment: .bottom) {
            Color.App.textSecondary.opacity(0.5)
                .frame(height: 1)
        }
        .textSelection(.enabled)
        .task {
            Task.detached(priority: .userInitiated) {
                let time = log.time ?? .now
                let date = await LogRow.formatter.string(from: time)
                let logDate = "\(date)"
                await MainActor.run {
                    self.logDate = logDate
                }
            }
        }
    }
}

struct LogRow_Previews: PreviewProvider {
    static var log: Log {
        Log(time: Date(), message: "", level: .error, id: UUID(), type: .internalLog, userInfo: [:])
    }

    static var previews: some View {
        LogRow(log: log)
    }
}
