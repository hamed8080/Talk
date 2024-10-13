//
//  DatePickerView.swift
//  Talk
//
//  Created by hamed on 10/12/24.
//

import Foundation
import UIKit
import SwiftUI
import TalkViewModels
import TalkModels

class DatePickerView: UIView {
    var completion: ((Date) -> Void)?
    var canceled: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("")
    }

    private lazy var datePicker: UIDatePicker = {
        let datePicker = UIDatePicker()
        datePicker.preferredDatePickerStyle = .inline
        datePicker.datePickerMode = .date
        datePicker.translatesAutoresizingMaskIntoConstraints = false
        datePicker.locale = Language.preferredLocale
        datePicker.calendar = Calendar(identifier: Language.isRTL ? .persian : .gregorian)
        return datePicker
    }()

    private lazy var cancelButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("General.cancel".bundleLocalized(), for: .normal)
        btn.addTarget(self, action: #selector(btnCanceledTapped), for: .touchUpInside)
        btn.titleLabel?.font = UIFont.uiiransansBody
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    private lazy var submitButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("General.submit".bundleLocalized(), for: .normal)
        btn.addTarget(self, action: #selector(btnSubmitTapped), for: .touchUpInside)
        btn.titleLabel?.font = UIFont.uiiransansBody
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    private func setup() {
        isUserInteractionEnabled = true

        addSubview(datePicker)
        addSubview(submitButton)
        addSubview(cancelButton)

        NSLayoutConstraint.activate([
            datePicker.topAnchor.constraint(equalTo: topAnchor),
            datePicker.leadingAnchor.constraint(equalTo: leadingAnchor),
            datePicker.trailingAnchor.constraint(equalTo: trailingAnchor),
            datePicker.bottomAnchor.constraint(equalTo: cancelButton.topAnchor, constant: -8),

            cancelButton.bottomAnchor.constraint(equalTo: bottomAnchor),
            cancelButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            cancelButton.heightAnchor.constraint(equalToConstant: 44),
            submitButton.bottomAnchor.constraint(equalTo: bottomAnchor),
            submitButton.trailingAnchor.constraint(equalTo: cancelButton.leadingAnchor, constant: -16),
            submitButton.heightAnchor.constraint(equalToConstant: 44),
        ])
    }

    @objc private func btnSubmitTapped(_ sender: UIButton) {
        completion?(datePicker.date)
    }

    @objc private func btnCanceledTapped(_ sender: UIButton) {
        canceled?()
    }
}

fileprivate struct DatePickerWrapper: UIViewRepresentable {
    public var completion: ((Date) -> Void)?
    @Environment(\.dismiss) var dismiss

    func makeUIView(context: Context) -> some UIView {
        let picker = DatePickerView()
        picker.completion = completion
        picker.canceled = {
            AppState.shared.objectsContainer.appOverlayVM.dialogView = nil
        }
        return picker
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {}
}

struct DatePickerDialogWrapper: View {
    let viewModel: ThreadViewModel?

    var body: some View {
        DatePickerWrapper { date in
            viewModel?.historyVM.moveToTimeByDate(time: UInt(date.millisecondsSince1970))
            AppState.shared.objectsContainer.appOverlayVM.dialogView = nil
        }
        .frame(width: AppState.shared.windowMode.isInSlimMode ? 310 : 320, height: 420)
    }
}
