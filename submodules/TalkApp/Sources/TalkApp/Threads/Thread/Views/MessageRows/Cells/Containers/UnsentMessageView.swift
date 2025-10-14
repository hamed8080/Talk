//
//  UnsentMessageView.swift
//  Talk
//
//  Created by hamed on 11/14/23.
//

import SwiftUI
import TalkUI
import TalkViewModels
import Chat
import TalkModels

final class UnsentMessageView: UIView {
    private let btnCancel = UIButton()
    private let btnResend = UIButton()
    private var heightConstraint: NSLayoutConstraint?

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureView() {
        translatesAutoresizingMaskIntoConstraints = false
        btnCancel.translatesAutoresizingMaskIntoConstraints = false
        btnResend.translatesAutoresizingMaskIntoConstraints = false
        btnCancel.accessibilityIdentifier = "btnCancelUnsentMessageView"
        btnResend.accessibilityIdentifier = "btnResendUnsentMessageView"

        btnCancel.setTitle("General.cancel".bundleLocalized(), for: .normal)
        btnResend.setTitle("Messages.resend".bundleLocalized(), for: .normal)

        addSubview(btnCancel)
        addSubview(btnResend)

        heightConstraint = heightAnchor.constraint(equalToConstant: 0)
        heightConstraint?.identifier = "UnsentMessageView"

        NSLayoutConstraint.activate([
            heightConstraint!,
            btnCancel.leadingAnchor.constraint(equalTo: leadingAnchor),
            btnCancel.topAnchor.constraint(equalTo: topAnchor),
            btnResend.topAnchor.constraint(equalTo: topAnchor),
            btnResend.leadingAnchor.constraint(equalTo: btnCancel.trailingAnchor, constant: ConstantSizes.unsentMessageViewBtnResendLeading),
        ])
    }

    public func set(_ viewModel: MessageRowViewModel) {
        if !viewModel.calMessage.rowType.isUnSent { return }
        let canShow = viewModel.message.isUnsentMessage
        btnCancel.setIsHidden(!canShow)
        btnResend.setIsHidden(!canShow)
        heightConstraint?.constant = canShow ? ConstantSizes.unsentMessageViewHeight : 0
    }
}

struct UnsentMessageViewWapper: UIViewRepresentable {
    let viewModel: MessageRowViewModel

    func makeUIView(context: Context) -> some UIView {
        return UnsentMessageView()
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {

    }
}

struct UnsentMessageView_Previews: PreviewProvider {
    static var previews: some View {
        let message = Message(id: 1, messageType: .participantJoin, time: 155600555)
        let viewModel = MessageRowViewModel(message: message, viewModel: .init(thread: .init(id: 1)))
        UnsentMessageViewWapper(viewModel: viewModel)
    }
}
