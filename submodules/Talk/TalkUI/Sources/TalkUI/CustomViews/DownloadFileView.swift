//
//  DownloadFileView.swift
//  TalkUI
//
//  Created by Hamed Hosseini on 5/27/21.
//

import AVFoundation
import Chat
import Combine
import SwiftUI
import TalkViewModels
import AVKit
import TalkModels

public struct DownloadFileView: View {
    let viewModel: DownloadFileViewModel
    var message: Message? { viewModel.message }

    public init(viewModel: DownloadFileViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        HStack(alignment: .center) {
            ZStack(alignment: .center) {
                MutableDownloadViews()
            }
        }
        .environmentObject(viewModel)
    }
}

struct MutableDownloadViews: View {
    @EnvironmentObject var viewModel: DownloadFileViewModel
    var message: Message? { viewModel.message }

    var body: some View {
        switch viewModel.state {
        case .completed:
            if let iconName = message?.iconName {
                Image(systemName: iconName)
                    .resizable()
                    .foregroundStyle(Color.App.white, Color.App.accent)
                    .scaledToFit()
                    .frame(width: 36, height: 36)
            }
        case .downloading, .started, .undefined, .thumbnail, .paused:
            if message?.isFileType == true {
                DownloadFileButton(message: message)
                    .padding(.horizontal, 4)
            }
        default:
           EmptyView()
        }
    }
}

struct DownloadFileButton: View {
    @EnvironmentObject var viewModel: DownloadFileViewModel
    let message: Message?
    var percent: Int64 { viewModel.downloadPercentValueNoLock() }
    var stateIcon: String {
        if viewModel.state == .downloading {
            return "pause.fill"
        } else if viewModel.state == .paused {
            return "play.fill"
        } else {
            return "arrow.down"
        }
    }

    var body: some View {
        HStack {
            ZStack {
                Image(systemName: stateIcon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 12, height: 12)
                    .foregroundStyle(Color.App.white)

                Circle()
                    .trim(from: 0.0, to: min(Double(percent) / 100, 1.0))
                    .stroke(style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                    .foregroundColor(Color.App.white)
                    .rotationEffect(Angle(degrees: 270))
                    .frame(width: 28, height: 28)
                    .rotateAnimtion(pause: viewModel.state == .paused)
                    .environment(\.layoutDirection, .leftToRight)
            }
            .frame(width: 36, height: 36)
            .background(Color.App.accent)
            .clipShape(RoundedRectangle(cornerRadius:(36 / 2)))
            .onTapGesture {
                if viewModel.state == .paused {
                    viewModel.resumeDownload()
                } else if viewModel.state == .downloading {
                    viewModel.pauseDownload()
                } else {
                    viewModel.startDownload()
                }
            }
        }
    }
}

struct DownloadFileView_Previews: PreviewProvider {
    struct Preview: View {
        @StateObject var viewModel: DownloadFileViewModel

        init() {
            let metadata = "{\"name\": \"Simulator Screenshot - iPhone 14 Pro Max - 2023-09-10 at 12.14.11\",\"file\": {\"hashCode\": \"UJMUIT4M194C5WLJ\",\"mimeType\": \"image/png\",\"fileHash\": \"UJMUIT4M194C5WLJ\",\"actualWidth\": 1290,\"actualHeight\": 2796,\"parentHash\": \"6MIPH7UM1P7OIZ2L\",\"size\": 1569454,\"link\": \"https://podspace.pod.ir/api/images/UJMUIT4M194C5WLJ?checkUserGroupAccess=true\",\"name\": \"Simulator Screenshot - iPhone 14 Pro Max - 2023-09-10 at 12.14.11\",\"originalName\": \"Simulator Screenshot - iPhone 14 Pro Max - 2023-09-10 at 12.14.11.png\"},\"fileHash\": \"UJMUIT4M194C5WLJ\"}"
            let message = Message(message: "Please download this file.",
                                  messageType: .file,
                                  metadata: metadata.string)
            let viewModel = DownloadFileViewModel(message: message)
            _viewModel = StateObject(wrappedValue: viewModel)
        }

        var body: some View {
            ZStack {
                DownloadFileView(viewModel: viewModel)
                    .environmentObject(AppOverlayViewModel())
            }
            .background(Color.App.color5)
            .onAppear {
                viewModel.state = .paused
            }
        }
    }

    static var previews: some View {
        Preview()
    }
}
