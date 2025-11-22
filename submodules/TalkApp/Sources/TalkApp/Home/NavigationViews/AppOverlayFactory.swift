//
//  AppOverlayFactory.swift
//  Talk
//
//  Created by hamed on 9/20/23.
//

import SwiftUI
import TalkUI
import TalkViewModels
import TalkExtensions
import TalkModels
import Chat

struct AppOverlayFactory: View {
    @EnvironmentObject var viewModel: AppOverlayViewModel

    var body: some View {
        switch viewModel.type {
        case .gallery(let galleryMessage):
            GalleryPageView()
                .environmentObject(GalleryViewModel(message: galleryMessage.message))
                .id(galleryMessage.message.id)
        case .galleryImageView(let image):
            ConversationImageView(image: image)
        case .dialog:
            if let dialog = viewModel.dialogView {
                if viewModel.clearBckground {
                    dialog
                        .ignoresSafeArea(.all)
                } else {
                    dialog
                        .background(.ultraThickMaterial)
                        .ignoresSafeArea(.all)
                }
            }
        case .toast(let leadingView, let message, let messageColor):
            ToastViewWrapper(message: message,
                             messageColor: messageColor!,
                             leadingView: leadingView) {
                /// OnSwipeDown
                viewModel.dismissToastImmediately()
            }
        case .error(let error):
            let isUnknown = error?.code == ServerErrorType.unknownError.rawValue
            if EnvironmentValues.isTalkTest, isUnknown {
                let title = String(format: "Errors.occuredTitle".bundleLocalized(), "\(error?.code ?? 0)")
                ToastViewWrapper(title: title,
                                 message: error?.message ?? "",
                                 showSandbox: true)
            } else if !isUnknown {
                if let localizedError = error?.localizedError {
                    ToastViewWrapper(title: "", message: localizedError)
                } else if error?.isPresentable == true {
                    let title = String(format: "Errors.occuredTitle".bundleLocalized(), "\(error?.code ?? 0)")
                    ToastViewWrapper(title: title, message: error?.message ?? "")
                } else if let appError = AppErrorTypes(rawValue: error?.code ?? 0) {
                    ToastViewWrapper(title: "", message: appError.localized)
                }
            }
        case .none:
            EmptyView()
                .frame(width: 0, height: 0)
                .hidden()
        }
    }
}

struct AppOverlayFactory_Previews: PreviewProvider {
    static var previews: some View {
        AppOverlayFactory()
    }
}

