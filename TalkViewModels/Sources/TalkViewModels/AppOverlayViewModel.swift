//
//  AppOverlayViewModel.swift
//  TalkViewModels
//
//  Created by hamed on 10/22/22.
//

import Combine
import ChatModels
import SwiftUI
import ChatCore

public enum AppOverlayTypes {
    case gallery(message: Message)
    case galleryImageView(uiimage: UIImage)
    case error(error: ChatError?)
    case dialog
    case none
}

public class AppOverlayViewModel: ObservableObject {
    @Published public var isPresented = false
    public var type: AppOverlayTypes = .none
    private var cancelableSet: Set<AnyCancellable> = .init()
    public var isError: Bool { AppState.shared.error != nil }
    public var showCloseButton: Bool = false

    public var transition: AnyTransition {
        switch type {
        case .gallery(message: _):
            return .asymmetric(insertion: .scale.animation(.interpolatingSpring(mass: 1.0, stiffness: 0.1, damping: 0.9, initialVelocity: 0.5).speed(30)), removal: .move(edge: .bottom))
        case .galleryImageView(uiimage: _):
            return .asymmetric(insertion: .scale.animation(.interpolatingSpring(mass: 1.0, stiffness: 0.1, damping: 0.9, initialVelocity: 0.5).speed(30)), removal: .opacity)
        case .error(error: _):
            return .asymmetric(insertion: .push(from: .bottom), removal: .move(edge: .bottom))
        case .dialog:
            return .scale.animation(.interpolatingSpring(mass: 1.0, stiffness: 0.1, damping: 0.9, initialVelocity: 0.5).speed(20))
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
            if let error = newValue {
                self?.type = .error(error: error)
                self?.isPresented = true
            } else if newValue == nil {
                self?.type = .none
                self?.isPresented = false
            }
        }
        .store(in: &cancelableSet)
    }

    public var galleryMessage: Message? = nil {
        didSet {
            guard let galleryMessage else { return }
            showCloseButton = true
            type = .gallery(message: galleryMessage)
            isPresented = true
        }
    }

    public var galleryImageView: UIImage? {
        didSet {
            guard let galleryImageView else { return }
            showCloseButton = true
            type = .galleryImageView(uiimage: galleryImageView)
            isPresented = true
        }
    }

    public var dialogView: AnyView? {
        didSet {
            if dialogView != nil {
                showCloseButton = false
                type = .dialog
                isPresented = true
            } else {
                showCloseButton = false
                type = .none
                isPresented = false
            }
        }
    }

    public func clear() {
        galleryMessage = nil
        galleryImageView = nil
    }
}
