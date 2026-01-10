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
    var hideControls: Bool = false {
        didSet {
            submitButton.isHidden = hideControls
            cancelButton.isHidden = hideControls
        }
    }
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
        let cal = Calendar(identifier: Language.isRTL ? .persian : .gregorian)
        datePicker.calendar = cal
        datePicker.timeZone = .gmt
        datePicker.minimumDate = cal.date(byAdding: .year, value: -100, to: Date())
        datePicker.maximumDate = Date()
        datePicker.setDate(Date(), animated: false)
        datePicker.tintColor = Color.App.accentUIColor
        return datePicker
    }()

    private lazy var cancelButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("General.cancel".bundleLocalized(), for: .normal)
        btn.addTarget(self, action: #selector(btnCanceledTapped), for: .touchUpInside)
        btn.titleLabel?.font = UIFont.bold(.body)
        btn.setTitleColor(Color.App.textSecondaryUIColor?.withAlphaComponent(0.8), for: .normal)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    private lazy var submitButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("General.submit".bundleLocalized(), for: .normal)
        btn.addTarget(self, action: #selector(btnSubmitTapped), for: .touchUpInside)
        btn.titleLabel?.font = UIFont.bold(.body)
        btn.setTitleColor(Color.App.textPrimaryUIColor, for: .normal)
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
            datePicker.bottomAnchor.constraint(equalTo: submitButton.topAnchor, constant: -8),

            submitButton.bottomAnchor.constraint(equalTo: bottomAnchor),
            submitButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            submitButton.heightAnchor.constraint(equalToConstant: 44),

            cancelButton.bottomAnchor.constraint(equalTo: bottomAnchor),
            cancelButton.trailingAnchor.constraint(equalTo: submitButton.leadingAnchor, constant: -16),
            cancelButton.heightAnchor.constraint(equalToConstant: 44),
        ])
    }

    @objc private func btnSubmitTapped(_ sender: UIButton) {
        let calendar = Calendar(identifier: Language.isRTL ? .persian : .gregorian)
        let pickedDate = datePicker.date
        let startOfDay = calendar.startOfDay(for: pickedDate)
        
        completion?(startOfDay)
    }

    @objc private func btnCanceledTapped(_ sender: UIButton) {
        canceled?()
    }

    public func setEnableDatePicker(_ enable: Bool) {
        datePicker.isEnabled = enable
        datePicker.layer.opacity = enable ? 1.0 : 0.5
    }
}

class UIDatePickerController: UIViewController {
    public var completion: ((Date) -> Void)?

    override var overrideUserInterfaceStyle: UIUserInterfaceStyle {
        get { AppSettingsModel.restore().isDarkMode == true ? .dark : .light }
        set { super.overrideUserInterfaceStyle = newValue }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }

    private func setup() {
        let picker = DatePickerView()
        picker.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(picker)

        view.backgroundColor = Color.App.bgPrimaryUIColor
        view.translatesAutoresizingMaskIntoConstraints = false

        picker.completion = { [weak self] selectedDate in
            guard let self = self else { return }
            dismiss(animated: true)
            completion?(selectedDate)
        }

        picker.canceled = { [weak self] in
            self?.dismiss(animated: true)
        }

        NSLayoutConstraint.activate([
            picker.topAnchor.constraint(equalTo: view.topAnchor),
            picker.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            picker.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            picker.heightAnchor.constraint(equalToConstant: 420),
        ])
    }
}

struct DatePickerWrapper: UIViewRepresentable {
    let hideControls: Bool
    var enableDatePicker: Bool = true
    public var completion: ((Date) -> Void)?
    @Environment(\.dismiss) var dismiss

    func makeUIView(context: Context) -> some UIView {
        let picker = DatePickerView()
        picker.hideControls = hideControls
        picker.completion = completion
        picker.setEnableDatePicker(enableDatePicker)
        picker.canceled = {
            AppState.shared.objectsContainer.appOverlayVM.dialogView = nil
        }
        return picker
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {}
}
