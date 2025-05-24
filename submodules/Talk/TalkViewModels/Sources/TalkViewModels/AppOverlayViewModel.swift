//
//  AppOverlayViewModel.swift
//  TalkViewModels
//
//  Created by hamed on 10/22/22.
//

import Combine
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
    case gallery(message: Message)
    case galleryImageView(uiimage: UIImage)
    case error(error: ChatError?)
    case toast(leadingView: AnyView?, message: String, messageColor: Color)
    case dialog
    case none
}

@MainActor
public class AppOverlayViewModel: ObservableObject {
    @Published public var isPresented = false
    public var type: AppOverlayTypes = .none
    private var cancelableSet: Set<AnyCancellable> = .init()
    public var isToast: Bool = false
    public var isError: Bool { AppState.shared.error != nil }
    public var showCloseButton: Bool = false
    public var offsetVM = GalleyOffsetViewModel()
    public var canDismiss: Bool = true
    public var toastTimer: Timer?

    public var transition: AnyTransition {
        switch type {
        case .gallery(message: _):
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

    public init() {
        AppState.shared.$error.sink { [weak self] newValue in
            self?.onError(newValue)
        }
        .store(in: &cancelableSet)
        offsetVM.appOverlayVM = self
    }

    private func onError(_ newError: ChatError?) {
        Task { [weak self] in
            await MainActor.run { [weak self] in
                self?.cancelToastTimer()
                if let error = newError {
                    self?.type = .error(error: error)
                    self?.isPresented = true
                } else if newError == nil {
                    self?.type = .none
                    self?.isPresented = false
                }
            }
        }
    }

    public var galleryMessage: Message? = nil {
        didSet {
            guard let galleryMessage else { return }
            cancelToastTimer()
            showCloseButton = true
            type = .gallery(message: galleryMessage)
            isPresented = true
        }
    }

    public var galleryImageView: UIImage? {
        didSet {
            guard let galleryImageView else { return }
            cancelToastTimer()
            showCloseButton = true
            type = .galleryImageView(uiimage: galleryImageView)
            isPresented = true
        }
    }

    public var dialogView: AnyView? {
        didSet {
            cancelToastTimer()
            if dialogView != nil {
                showCloseButton = false
                type = .dialog
                isPresented = true
            } else {
                showCloseButton = false
                type = .none
                isPresented = false
                animateObjectWillChange()
            }
        }
    }
    
    public func dialogView(canDismiss: Bool, view: AnyView?) {
        if view != nil {
            dialogView = view
            self.canDismiss = canDismiss
            showCloseButton = false
            type = .dialog
            isPresented = true
            animateObjectWillChange()
        } else {
            dialogView = nil
            self.canDismiss = true
            showCloseButton = false
            type = .none
            isPresented = false
            animateObjectWillChange()
        }
    }

    public func toast<T: View>(leadingView: T, message: String, messageColor: Color, duration: ToastDuration = .fast) {
        type = .toast(leadingView: AnyView(leadingView), message: message, messageColor: messageColor)
        isToast = true
        isPresented = true
        showCloseButton = false
        animateObjectWillChange()
        cancelToastTimer()
        toastTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(duration.duration), repeats: false) { [weak self] timer in
            if !timer.isValid { return }
            Task { @MainActor [weak self] in
                self?.isToast = false
                self?.type = .none
                self?.isPresented = false
                self?.animateObjectWillChange()
            }
        }
    }

    public func clear() {
        /// Prevent memory leak by preventing setting type to .none to prevent recalling AppOverlayFactory Views twice.
        type = .none
        galleryMessage = nil
        galleryImageView = nil
    }
    
    private func cancelToastTimer() {
        toastTimer?.invalidate()
        toastTimer = nil
    }
}
