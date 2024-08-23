//
//  FullScreenBackgroundView.swift
//  TalkUI
//
//  Created by hamed on 3/14/23.
//

import SwiftUI

public struct FullScreenBackgroundView: UIViewRepresentable {
    private let view: UIView

    public init(view: UIView) {
        self.view = view
    }

    public func makeUIView(context: Context) -> UIView {
        DispatchQueue.main.async {
            view.superview?.superview?.backgroundColor = .clear
        }
        return view
    }

    public func updateUIView(_ uiView: UIView, context: Context) {}
}

struct FullScreenBackgroundViewModifier: ViewModifier {

    private var view: UIView

    init (view: UIView) {
        self.view = view
    }

    func body(content: Content) -> some View {
        content.background(FullScreenBackgroundView(view: view))
    }
}

public extension View {
    func fullScreenBackgroundView(view: UIView = UIVisualEffectView(effect: UIBlurEffect(style: .prominent))) -> some View {
        modifier(FullScreenBackgroundViewModifier(view: view))
    }
}

struct SwiftUIView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Text("Test")
        }
        .fullScreenBackgroundView()
    }
}
