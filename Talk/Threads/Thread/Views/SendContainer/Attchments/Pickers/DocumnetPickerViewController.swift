//
//  DocumnetPickerViewController.swift
//  Talk
//
//  Created by hamed on 6/17/24.
//

import Foundation
import TalkUI
import UIKit
import TalkViewModels
import MobileCoreServices

public final class DocumnetPickerViewController: NSObject, UIDocumentPickerDelegate {
    public weak var viewModel: ThreadViewModel?

    public func present(vc: UIViewController?) {
        let picker: UIDocumentPickerViewController
        if #available(iOS 14, *) {
            picker = UIDocumentPickerViewController(forOpeningContentTypes: [.item], asCopy: true)
        } else {
            picker = UIDocumentPickerViewController(documentTypes: [kUTTypeItem as String], in: .import)
        }
        picker.allowsMultipleSelection = true
        picker.delegate = self
        picker.modalPresentationStyle = .formSheet
        vc?.present(picker, animated: true)
    }

    public func documentPicker(_: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        viewModel?.attachmentsViewModel.onDocumentPicker(urls)
    }

    public func documentPickerWasCancelled(_: UIDocumentPickerViewController) {

    }
}
