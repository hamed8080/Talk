//
//  File.swift
//  
//
//  Created by hamed on 2/13/24.
//

import Foundation
import SwiftUI
import SafariServices
import TalkViewModels

public struct OpenURLView: View {
    @EnvironmentObject var appState: AppState
    @State private var isPresented: Binding<Bool> = Binding(get: { AppState.shared.appStateNavigationModel.openURL != nil }, set: { _ in })

    public init(){}

    public var body: some View {
        if let url = appState.appStateNavigationModel.openURL {
            Rectangle()
                .fullScreenCover(isPresented: isPresented) {
                    OpenURLViewControllerRepresentable(url: url) {
                        appState.appStateNavigationModel.openURL = nil
                        appState.animateObjectWillChange()
                    }
                    .ignoresSafeArea()
                }
        }
    }
}

struct OpenURLViewControllerRepresentable: UIViewControllerRepresentable {
    let url: URL
    let onDismiss: () -> Void

    func makeUIViewController(context: Context) -> some UIViewController {
        let vc = SFSafariViewController(url: url)
        vc.preferredControlTintColor = UIColor(named: "accent")
        vc.delegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {

    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onDismiss: onDismiss)
    }

    class Coordinator: NSObject, SFSafariViewControllerDelegate {
        let onDismiss: () -> Void

        init(onDismiss: @escaping () -> Void) {
            self.onDismiss = onDismiss
        }

        func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
            onDismiss()
        }
    }
}
