//
//  AppOverlayViewModel.swift
//  TalkViewModels
//
//  Created by hamed on 10/22/22.
//

import SwiftUI
import Chat

public enum ToastDuration {
    case fast
    case slow
    case custom(duration: Int)

    var duration: Int {
        switch self {
        case .fast:
            return 3
        case .slow:
            return 6
        case .custom(let duration):
            return duration
        }
    }
}

public enum AppOverlayTypes {
    case gallery(GalleryMessage)
    case galleryImageView(uiimage: UIImage)
    case error(error: ChatError?)
    case toast(leadingView: UIView?, message: String, messageColor: UIColor?)
    case dialog
    case none
}

@MainActor
public class AppOverlayViewModel: ObservableObject {
    @Published public var isPresented = false
    public var type: AppOverlayTypes = .none
    public weak var toastAttachToVC: UIViewController?
    public var isToast: Bool = false
    public var isError: Bool { error != nil }
    public var canDismiss: Bool = true
    public var toastTimer: Timer?
    public var clearBckground: Bool = false
    private var error: ChatError?

    public var transition: AnyTransition {
        switch type {
        case .gallery(let _):
            return .opacity
        case .galleryImageView(uiimage: _):
            return .asymmetric(insertion: .scale.animation(.interpolatingSpring(mass: 1.0, stiffness: 0.1, damping: 0.9, initialVelocity: 0.5).speed(30)), removal: .opacity)
        case .error(error: _):
            return .opacity
        case .dialog:
            return .asymmetric(
                insertion: .scale.combined(with: .opacity)
                    .animation(.interpolatingSpring(mass: 1.0, stiffness: 0.2, damping: 0.9, initialVelocity: 0.4).speed(20)),
                removal: .scale.combined(with: .opacity)
                    .animation(.easeInOut(duration: 0.15))
            )
        default:
            return .opacity
        }
    }

    public var radius: CGFloat {
        switch type {
        case .dialog:
            return 12
        default:
            return 0
        }
    }

    public init() { }

    public var galleryMessage: GalleryMessage? = nil {
        didSet {
            guard let galleryMessage else { return }
            cancelToastTimer()
            type = .gallery(galleryMessage)
            isPresented = true
        }
    }

    public var galleryImageView: UIImage? {
        didSet {
            guard let galleryImageView else { return }
            cancelToastTimer()
            type = .galleryImageView(uiimage: galleryImageView)
            isPresented = true
        }
    }

    public var dialogView: AnyView? {
        didSet {
            cancelToastTimer()
            if dialogView != nil {
                isToast = false
                cancelToastTimer()
                type = .dialog
                isPresented = true
            } else {
                clearBckground = false
                type = .none
                isPresented = false
                animateObjectWillChange()
            }
        }
    }
    
    public func dialogView(canDismiss: Bool, view: AnyView?) {
        if view != nil {
            isToast = false
            cancelToastTimer()
            dialogView = view
            self.canDismiss = canDismiss
            type = .dialog
            isPresented = true
            animateObjectWillChange()
        } else {
            dialogView = nil
            self.canDismiss = true
            type = .none
            isPresented = false
            animateObjectWillChange()
        }
    }

    public func toast(leadingView: UIView?, message: String, messageColor: UIColor, duration: ToastDuration = .fast) {
        type = .toast(leadingView: leadingView, message: message, messageColor: messageColor)
        isToast = true
        isPresented = true
        animateObjectWillChange()
        cancelToastTimer()
        toastTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(duration.duration), repeats: false) { [weak self] timer in
            if !timer.isValid { return }
            Task { @MainActor [weak self] in
                self?.isToast = false
                self?.type = .none
                self?.isPresented = false
                self?.toastAttachToVC = nil
                self?.animateObjectWillChange()
            }
        }
    }

    public func clear() {
        /// Prevent memory leak by preventing setting type to .none to prevent recalling AppOverlayFactory Views twice.
        type = .none
        toastAttachToVC = nil
        galleryMessage = nil
        galleryImageView = nil
    }
    
    private func cancelToastTimer() {
        toastTimer?.invalidate()
        toastTimer = nil
    }
}

extension AppOverlayViewModel {
    public func showErrorToast(_ error: ChatError) {
        /// Cancel the old timer to prevent dismissing the new error.
        cancelToastTimer()
        
        self.error = error
        type = .error(error: error)
        isPresented = true
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            try await Task.sleep(for: .seconds(5))
            self.error = nil
            type = .none
            isPresented = false
        }
    }
}

public struct GalleryMessage {
    public let message: Message
    public let goToHistoryTapped: (() -> Void)?
    
    public init(message: Message, goToHistoryTapped: (() -> Void)? = nil) {
        self.message = message
        self.goToHistoryTapped = goToHistoryTapped
    }
}
