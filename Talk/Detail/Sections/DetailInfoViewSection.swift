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
    @StateObject private var fullScreenImageLoader: ImageLoaderViewModel
    // We have to use Thread ViewModel.thread as a reference when an update thread info will happen the only object that gets an update is this.
    private var thread: Conversation { threadVM.thread }
    @State private var cachedImage: UIImage?
    @State private var showDownloading: Bool = false

    init(viewModel: ThreadDetailViewModel, threadVM: ThreadViewModel) {
        let config = DetailInfoViewSection.fullScreenAvatarConfig(viewModel: viewModel)
        self._fullScreenImageLoader = .init(wrappedValue: .init(config: config))
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

    private var imageLink: String {
        let image = thread.computedImageURL ?? viewModel.participantDetailViewModel?.participant.image ?? ""
        return image.replacingOccurrences(of: "http://", with: "https://")
    }
    
    private static func fullScreenAvatarConfig(viewModel: ThreadDetailViewModel) -> ImageLoaderConfig {
        // Prepare image config of either the thread or user to be fetched forcefully
        let image = viewModel.thread?.computedImageURL ?? viewModel.participantDetailViewModel?.participant.image
        let httpsImage = image?.replacingOccurrences(of: "http://", with: "https://")
        let config = ImageLoaderConfig(url: httpsImage ?? "",
                                       size: .ACTUAL,
                                       metaData: viewModel.thread?.metadata,
                                       userName: String.splitedCharacter(viewModel.thread?.title ?? ""),
                                       forceToDownloadFromServer: true)
        return config
    }

    private var avatarVM: ImageLoaderViewModel {
        let threadsVM = AppState.shared.objectsContainer.threadsVM
        let avatarVM = threadsVM.avatars(for: imageLink, metaData: thread.metadata, userName: String.splitedCharacter(thread.title ?? ""))
        return avatarVM
    }

    @ViewBuilder
    private var imageView: some View {
        ImageLoaderView(imageLoader: avatarVM)
            .id("\(imageLink)\(thread.id ?? 0)")
            .font(.system(size: 16).weight(.heavy))
            .foregroundColor(.white)
            .frame(width: 64, height: 64)
            .background(Color(uiColor: String.getMaterialColorByCharCode(str: viewModel.thread?.title ?? viewModel.participantDetailViewModel?.participant.name ?? "")))
            .clipShape(RoundedRectangle(cornerRadius:(28)))
            .overlay {
                if thread.type == .selfThread {
                    SelfThreadImageView(imageSize: 64, iconSize: 28)
                }
                if showDownloading {
                    ProgressView()
                }
            }
            .onTapGesture {
                onTapAvatarAction()
            }
            .onReceive(fullScreenImageLoader.$image) { newValue in
                if newValue.size.width > 0, cachedImage == nil {
                    onDonwloadAavtarCompleted(image: newValue)
                }
            }
    }
    
    private func onTapAvatarAction() {
        // We use cache image because in init fullScreenImageLoader we always set forcetodownload for image to true
        if cachedImage == nil {
            showDownloading = true
            fullScreenImageLoader.fetch()
        } else {
            appOverlayVM.galleryImageView = cachedImage
        }
    }
    
    private func onDonwloadAavtarCompleted(image: UIImage) {
        appOverlayVM.galleryImageView = image
        showDownloading = false
        cachedImage = image
    }

    private var threadTitle: some View {
        HStack {
            let threadName = viewModel.participantDetailViewModel?.participant.contactName ?? thread.titleRTLString.stringToScalarEmoji()
            Text(threadName)
                .font(.iransansBody)
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
            let localized = String(localized: .init("Contacts.lastVisited"), bundle: Language.preferedBundle)
            let formatted = String(format: localized, notSeenString)
            Text(formatted)
                .font(.iransansCaption3)
        }
    }
}

struct DetailInfoViewSection_Previews: PreviewProvider {
    static var previews: some View {
        DetailInfoViewSection(viewModel: .init(), threadVM: .init(thread: .init()))
    }
}
