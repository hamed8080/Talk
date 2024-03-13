//
//  UnsentMessageView.swift
//  Talk
//
//  Created by hamed on 11/14/23.
//

import SwiftUI
import TalkUI
import TalkViewModels
import ChatModels

final class UnsentMessageView: UIView {
    private let btnCancel = UIButton()
    private let btnResend = UIButton()

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

        btnCancel.setTitle("General.cancel".localized(), for: .normal)
        btnResend.setTitle("Messages.resend".localized(), for: .normal)

        addSubview(btnCancel)
        addSubview(btnResend)

        NSLayoutConstraint.activate([
            btnCancel.leadingAnchor.constraint(equalTo: leadingAnchor),
            btnCancel.topAnchor.constraint(equalTo: topAnchor),
            btnResend.topAnchor.constraint(equalTo: topAnchor),
            btnResend.leadingAnchor.constraint(equalTo: btnCancel.trailingAnchor, constant: 8),
        ])
    }

    public func set(_ viewModel: MessageRowViewModel) {
        let canShow = viewModel.message.isUnsentMessage
        btnCancel.isHidden = !canShow
        btnResend.isHidden = !canShow
        isHidden = !canShow
        heightAnchor.constraint(equalToConstant:  canShow ? 28 : 0).isActive = true
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
