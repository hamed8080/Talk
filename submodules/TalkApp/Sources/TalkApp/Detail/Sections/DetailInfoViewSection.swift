//
//  DetailInfoViewSection.swift
//  Talk
//
//  Created by hamed on 5/6/24.
//

import SwiftUI
import TalkViewModels
import TalkModels
import TalkUI
import Chat
import TalkExtensions

struct DetailInfoViewSection: View {
    @EnvironmentObject var appOverlayVM: AppOverlayViewModel
    @EnvironmentObject var viewModel: ThreadDetailViewModel
    var threadVM: ThreadViewModel
    // We have to use Thread ViewModel.thread as a reference when an update thread info will happen the only object that gets an update is this.
    private var thread: Conversation { threadVM.thread }

    init(threadVM: ThreadViewModel) {
        self.threadVM = threadVM
    }

    var body: some View {
        HStack(spacing: 16) {
            imageView
            VStack(alignment: .leading, spacing: 4) {
                threadTitle
                participantsCount
                lastSeen
            }
            Spacer()
        }
        .frame(height: 56)
        .frame(minWidth: 0, maxWidth: .infinity)
        .padding(.all, 16)
        .background(Color.App.dividerPrimary)
    }

    @ViewBuilder
    private var imageView: some View {
        if let imageLoaderVM = viewModel.avatarVM {
            ImageLoaderView(imageLoader: imageLoaderVM)
                .id("\(viewModel.imageLink)\(thread.id ?? 0)")
                .font(.system(size: 16).weight(.heavy))
                .foregroundColor(.white)
                .frame(width: 64, height: 64)
                .background(Color(uiColor: String.getMaterialColorByCharCode(str: viewModel.thread?.title ?? viewModel.participantDetailViewModel?.participant.name ?? "")))
                .clipShape(RoundedRectangle(cornerRadius:(28)))
                .overlay {
                    if thread.type == .selfThread {
                        SelfThreadImageView(imageSize: 64, iconSize: 28)
                    }
                    if viewModel.showDownloading {
                        ProgressView()
                    }
                }
                .onTapGesture {
                    viewModel.onTapAvatarAction()
                }
        }
    }
    
    private var threadTitle: some View {
        HStack {
            let threadName = viewModel.participantDetailViewModel?.participant.contactName ?? thread.titleRTLString.stringToScalarEmoji()
            Text(threadName)
                .font(.fBody)
                .foregroundStyle(Color.App.textPrimary)

            if thread.isTalk == true {
                Image("ic_approved")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                    .offset(x: -4)
            }
        }
    }

    @ViewBuilder
    private var participantsCount: some View {
        if thread.group == true, let threadVM = viewModel.threadVM {
            DetailViewNumberOfParticipants(viewModel: threadVM)
        }
    }

    @ViewBuilder
    private var lastSeen: some View {
        if let notSeenString = viewModel.participantDetailViewModel?.notSeenString {
            let localized = "Contacts.lastVisited".bundleLocalized()
            let formatted = String(format: localized, notSeenString)
            Text(formatted)
                .font(.fCaption3)
        }
    }
}

struct DetailInfoViewSection_Previews: PreviewProvider {
    static var previews: some View {
        DetailInfoViewSection(threadVM: .init(thread: .init()))
    }
}
