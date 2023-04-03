//
//  DownloadFileView.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import AVFoundation
import Chat
import Combine
import SwiftUI

struct DownloadFileView: View {
    @StateObject var downloadFileVM = DownloadFileViewModel()
    @State var shareDownloadedFile: Bool = false
    let message: Message

    init(message: Message, placeHolder: Data? = nil) {
        self.message = message
        if let placeHolder = placeHolder {
            downloadFileVM.data = placeHolder
        }
    }

    var body: some View {
        HStack {
            ZStack(alignment: .center) {
                switch downloadFileVM.state {
                case .COMPLETED:
                    if let fileURL = downloadFileVM.fileURL, let scaledImage = fileURL.imageScale(width: 420)?.image {
                        Image(cgImage: scaledImage)
                            .resizable()
                            .scaledToFit()
                    } else if message.isAudio, let fileURL = downloadFileVM.fileURL {
                        AudioPlayer(viewModel: AVAudioPlayerViewModel(fileURL: fileURL, ext: message.fileMetaData?.file?.mimeType?.ext))
                            .id(fileURL)
                    } else {
                        Image(systemName: message.iconName)
                            .resizable()
                            .padding()
                            .foregroundColor(.iconColor.opacity(0.8))
                            .scaledToFit()
                            .frame(width: 64, height: 64)
                            .onTapGesture {
                                shareDownloadedFile.toggle()
                            }
                    }
                case .DOWNLOADING, .STARTED:
                    CircularProgressView(percent: $downloadFileVM.downloadPercent)
                        .padding()
                        .frame(maxWidth: 128)
                        .onTapGesture {
                            downloadFileVM.pauseDownload()
                        }
                case .PAUSED:
                    Image(systemName: "pause.circle")
                        .resizable()
                        .padding()
                        .font(.headline.weight(.thin))
                        .foregroundColor(.indigo)
                        .scaledToFit()
                        .frame(width: 64, height: 64)
                        .frame(maxWidth: 128)
                        .onTapGesture {
                            downloadFileVM.resumeDownload()
                        }
                case .UNDEFINED:
                    Rectangle()
                        .fill(Color.primary.opacity(0.1))
                        .blur(radius: 24)

                    Image(systemName: "arrow.down.circle")
                        .resizable()
                        .font(.headline.weight(.thin))
                        .padding(32)
                        .frame(width: 96, height: 96)
                        .scaledToFit()
                        .foregroundColor(.indigo)
                        .onTapGesture {
                            downloadFileVM.startDownload()
                        }
                default:
                    EmptyView()
                }
            }
        }
        .animation(.easeInOut, value: downloadFileVM.state)
        .animation(.easeInOut, value: downloadFileVM.data)
        .animation(.easeInOut, value: downloadFileVM.downloadPercent)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sheet(isPresented: $shareDownloadedFile) {
            if let fileURL = downloadFileVM.fileURL {
                ActivityViewControllerWrapper(activityItems: [fileURL])
            } else {
                EmptyView()
            }
        }
        .onAppear {
            downloadFileVM.setMessage(message: message)
        }
    }
}

struct AudioPlayer: View {
    @StateObject var viewModel: AVAudioPlayerViewModel

    var body: some View {
        VStack {
            Image(systemName: !viewModel.isPlaying ? "play.circle.fill" : "pause.circle.fill")
                .resizable()
                .foregroundColor(.blue)
                .frame(width: 48, height: 48, alignment: .leading)
                .cornerRadius(24)
                .animation(.easeInOut, value: viewModel.isPlaying)
                .onTapGesture {
                    viewModel.toggle()
                }
        }
        .padding()
        .onAppear {
            viewModel.setup()
        }
    }
}

final class AVAudioPlayerViewModel: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published var isPlaying: Bool = false
    @Published var player: AVAudioPlayer?
    var fileURL: URL
    var ext: String?

    init(fileURL: URL, ext: String?) {
        self.fileURL = Bundle.main.url(forResource: "Tamasha", withExtension: "mp3") ?? fileURL
        self.ext = ext
    }

    func setup() {
        if player != nil { return }
        do {
            let audioData = try Data(contentsOf: fileURL, options: NSData.ReadingOptions.mappedIfSafe)
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback)
            player = try AVAudioPlayer(data: audioData, fileTypeHint: ext)
            player?.delegate = self
        } catch let error as NSError {
            print(error.description)
        }
    }

    func toggle() {
        isPlaying.toggle()
        try? AVAudioSession.sharedInstance().setActive(isPlaying)
        if isPlaying {
            player?.prepareToPlay()
            player?.play()
        } else {
            player?.pause()
        }
    }

    func audioPlayerDidFinishPlaying(_: AVAudioPlayer, successfully _: Bool) {
        isPlaying = false
    }
}

enum DownloadFileState {
    case STARTED
    case COMPLETED
    case DOWNLOADING
    case PAUSED
    case ERROR
    case UNDEFINED
}

protocol DownloadFileViewModelProtocol {
    var message: Message? { get }
    var fileHashCode: String { get }
    var data: Data? { get }
    var state: DownloadFileState { get }
    var downloadUniqueId: String? { get }
    var downloadPercent: Int64 { get }
    var url: URL? { get }
    var fileURL: URL? { get }
    func setMessage(message: Message)
    func startDownload()
    func pauseDownload()
    func resumeDownload()
}

final class DownloadFileViewModel: ObservableObject, DownloadFileViewModelProtocol {
    @Published var downloadPercent: Int64 = 0
    @Published var state: DownloadFileState = .UNDEFINED
    @Published var data: Data?
    var fileHashCode: String { message?.fileMetaData?.fileHash ?? message?.fileMetaData?.file?.hashCode ?? "" }
    let cm: CacheFileManagerProtocol? = AppState.shared.cacheFileManager

    var fileURL: URL? {
        guard let url = url else { return nil }
        return cm?.filePath(url: url) ?? cm?.filePathInGroup(url: url)
    }

    var url: URL? {
        let path = message?.isImage == true ? Routes.images.rawValue : Routes.files.rawValue
        let url = "\(ChatManager.activeInstance?.config.fileServer ?? "")\(path)/\(fileHashCode)"
        return URL(string: url)
    }

    var downloadUniqueId: String?
    private(set) var message: Message?
    private var cancelable: Set<AnyCancellable> = []

    init() {}

    func setMessage(message: Message) {
        self.message = message
        if isInCache {
            state = .COMPLETED
        }
        NotificationCenter.default.publisher(for: .fileDeletedFromCacheName)
            .compactMap { $0.object as? Message }
            .filter { $0.id == message.id }
            .sink { [weak self] _ in
                self?.state = .UNDEFINED
            }
            .store(in: &cancelable)
    }

    var isInCache: Bool {
        guard let url = url else { return false }
        return cm?.isFileExist(url: url) ?? false || cm?.isFileExistInGroup(url: url) ?? false
    }

    func startDownload() {
        if !isInCache, message?.isImage == true {
            downloadImage()
        } else {
            downloadFile()
        }
    }

    private func downloadFile() {
        state = .DOWNLOADING
        let req = FileRequest(hashCode: fileHashCode, forceToDownloadFromServer: true)
        ChatManager.activeInstance?.getFile(req) { downloadProgress in
            self.downloadPercent = downloadProgress.percent
        } completion: { [weak self] data, _, _, _ in
            self?.onResponse(data: data)
        } cacheResponse: { [weak self] _, url, _, _ in
            if let url = url, let data = self?.cm?.getData(url: url) {
                self?.onResponse(data: data)
            }
        } uniqueIdResult: { uniqueId in
            self.downloadUniqueId = uniqueId
        }
    }

    private func downloadImage() {
        state = .DOWNLOADING
        let req = ImageRequest(hashCode: fileHashCode, forceToDownloadFromServer: true, size: .ACTUAL)
        ChatManager.activeInstance?.getImage(req) { [weak self] downloadProgress in
            self?.downloadPercent = downloadProgress.percent
        } completion: { [weak self] data, _, _, _ in
            self?.onResponse(data: data)
        } cacheResponse: { [weak self] _, url, _, _ in
            if let url = url, let data = self?.cm?.getData(url: url) {
                self?.onResponse(data: data)
            }
        } uniqueIdResult: { [weak self] uniqueId in
            self?.downloadUniqueId = uniqueId
        }
    }

    private func onResponse(data: Data?) {
        if let data = data {
            state = .COMPLETED
            downloadPercent = 100
            self.data = data
        }
    }

    func pauseDownload() {
        guard let downloadUniqueId = downloadUniqueId else { return }
        ChatManager.activeInstance?.manageDownload(uniqueId: downloadUniqueId, action: .suspend) { [weak self] _, _ in
            self?.state = .PAUSED
        }
    }

    func resumeDownload() {
        guard let downloadUniqueId = downloadUniqueId else { return }
        ChatManager.activeInstance?.manageDownload(uniqueId: downloadUniqueId, action: .resume) { [weak self] _, _ in
            self?.state = .DOWNLOADING
        }
    }
}

struct DownloadFileView_Previews: PreviewProvider {
    static var previews: some View {
        DownloadFileView(message: Message(message: "Hello"), placeHolder: UIImage(named: "avatar")?.pngData())
    }
}
