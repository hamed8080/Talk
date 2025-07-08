//
//  LeitnerBoxContactPickerView.swift
//  LeitnerBoxApp
//
//  Created by Hamed Hosseini on 3/8/25.
//

import ContactsUI
import SwiftUI
import MessageUI

// MARK: - Contact Picker View
struct LeitnerBoxContactPickerView: UIViewControllerRepresentable {
    var onContactSelected: (String?) -> Void
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
    
    func makeUIViewController(context: Context) -> CNContactPickerViewController {
        let picker = CNContactPickerViewController()
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: CNContactPickerViewController, context: Context) {}

    @MainActor
    class Coordinator: NSObject, @preconcurrency CNContactPickerDelegate {
        var parent: LeitnerBoxContactPickerView
        
        init(_ parent: LeitnerBoxContactPickerView) {
            self.parent = parent
        }

        func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
            if let phoneNumber = contact.phoneNumbers.first?.value.stringValue {
                parent.onContactSelected(phoneNumber)
            } else {
                parent.onContactSelected(nil)
            }
        }

        func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
            parent.onContactSelected(nil)
        }
    }
}

// MARK: - SMS Composer View
struct LeitnerBoxMessageComposerView: UIViewControllerRepresentable {
    let recipients: [String]
    let body: String
    
    static func canSendText() -> Bool {
        MFMessageComposeViewController.canSendText()
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }

    func makeUIViewController(context: Context) -> MFMessageComposeViewController {
        let controller = MFMessageComposeViewController()
        controller.messageComposeDelegate = context.coordinator
        controller.recipients = recipients
        controller.body = body
        return controller
    }

    func updateUIViewController(_ uiViewController: MFMessageComposeViewController, context: Context) {}

    @MainActor
    class Coordinator: NSObject, @preconcurrency MFMessageComposeViewControllerDelegate {
        var parent: LeitnerBoxMessageComposerView

        init(_ parent: LeitnerBoxMessageComposerView) {
            self.parent = parent
        }

        func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
            controller.dismiss(animated: true)
        }
    }
}

// MARK: - Share Sheet for iPad
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        controller.popoverPresentationController?.sourceView = UIApplication.shared.windows.first
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
