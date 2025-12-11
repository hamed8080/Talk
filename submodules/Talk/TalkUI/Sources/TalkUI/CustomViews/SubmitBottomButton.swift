//
//  SubmitBottomButton.swift
//  TalkUI
//
//  Created by hamed on 2/20/22.
//

import SwiftUI

public struct SubmitBottomButton: View {
    @Binding var isLoading: Bool
    @Binding var enableButton: Bool
    let text: String
    let color: Color
    let maxInnerWidth: CGFloat
    let action: (()-> Void)?


    public init(text: String,
                enableButton: Binding<Bool> = .constant(true),
                isLoading: Binding<Bool> = .constant(false),
                maxInnerWidth: CGFloat = .infinity,
                color: Color = Color.App.accent,
                action: (()-> Void)? = nil)
    {
        self.action = action
        self.maxInnerWidth = maxInnerWidth
        self._enableButton = enableButton
        self._isLoading = isLoading
        self.text = text
        self.color = color
    }

    public var body: some View {
        HStack {
            Button {
                withAnimation {
                    action?()
                }
            } label: {
                HStack(spacing: 8) {
                    Spacer()
                    Text(text)
                        .font(Font.normal(.body))
                        .contentShape(Rectangle())
                        .foregroundStyle(Color.App.textPrimary)
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(.circular)
                    }
                    Spacer()
                }
                .frame(minWidth: 0, maxWidth: maxInnerWidth)
                .contentShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
            .frame(height: 48)
            .contentShape(RoundedRectangle(cornerRadius: 8))
            .background(color)
            .clipShape(RoundedRectangle(cornerRadius:(8)))
            .disabled(!enableButton)
            .opacity(enableButton ? 1.0 : 0.3)
        }
        .frame(minWidth: 0, maxWidth: .infinity)
        .padding()
        .background(.ultraThinMaterial)
    }
}

public final class SubmitBottomButtonUIView: UIView {
    private let btnSubmit = UIButton(type: .system)
    private let progressView = UIProgressView()
    private let text: String
    private let color: UIColor
    public var action: (()-> Void)?

    public init(text: String, color: UIColor = Color.App.accentUIColor!) {
        self.text = text
        self.color = color
        super.init(frame: .zero)
        configureView()
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureView() {
        btnSubmit.translatesAutoresizingMaskIntoConstraints = false
        btnSubmit.layer.masksToBounds = true
        btnSubmit.layer.cornerRadius = 12
        btnSubmit.backgroundColor = color
        btnSubmit.titleLabel?.font = UIFont.normal(.body)
        btnSubmit.addTarget(self, action: #selector(submitTapped), for: .touchUpInside)
        btnSubmit.setTitle(text.bundleLocalized(), for: .normal)
        btnSubmit.setTitleColor(Color.App.textPrimaryUIColor, for: .normal)

        let blurEffect = UIBlurEffect(style: .systemThinMaterial)
        let effectView = UIVisualEffectView(effect: blurEffect)
        effectView.translatesAutoresizingMaskIntoConstraints = false

        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.isHidden = true

        let hStack = UIStackView()
        hStack.translatesAutoresizingMaskIntoConstraints = false
        hStack.axis = .horizontal
        hStack.spacing = 8
        hStack.alignment = .leading
        hStack.addArrangedSubview(btnSubmit)
        hStack.addArrangedSubview(progressView)

        addSubview(effectView)
        addSubview(hStack)

        NSLayoutConstraint.activate([
            btnSubmit.heightAnchor.constraint(equalToConstant: 48),
            hStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            hStack.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            hStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            hStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
            effectView.trailingAnchor.constraint(equalTo: trailingAnchor),
            effectView.topAnchor.constraint(equalTo: topAnchor),
            effectView.leadingAnchor.constraint(equalTo: leadingAnchor),
            effectView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    @objc private func submitTapped(_ sender: UIButton) {
        action?()
    }

    public func update(enable: Bool = true, isLoading: Bool = false) {
        btnSubmit.isEnabled = enable
        progressView.isHidden = !isLoading
    }
}

public struct SubmitBottomLabel: View {
    @Binding var isLoading: Bool
    @Binding var enableButton: Bool
    let text: String
    let color: Color
    let maxInnerWidth: CGFloat

    public init(text: String,
                enableButton: Binding<Bool> = .constant(true),
                isLoading: Binding<Bool> = .constant(false),
                maxInnerWidth: CGFloat = .infinity,
                color: Color = Color.App.accent)
    {
        self.maxInnerWidth = maxInnerWidth
        self._enableButton = enableButton
        self._isLoading = isLoading
        self.text = text
        self.color = color
    }

    public var body: some View {
        HStack {
            HStack(spacing: 8) {
                Spacer()
                Text(text)
                    .font(Font.normal(.body))
                    .contentShape(Rectangle())
                    .foregroundStyle(Color.App.textPrimary)
                if isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                }
                Spacer()
            }
            .frame(minWidth: 0, maxWidth: maxInnerWidth)
            .contentShape(RoundedRectangle(cornerRadius: 8))
            .buttonStyle(.plain)
            .frame(height: 48)
            .contentShape(RoundedRectangle(cornerRadius: 8))
            .background(color)
            .clipShape(RoundedRectangle(cornerRadius:(8)))
            .disabled(!enableButton)
            .opacity(enableButton ? 1.0 : 0.3)
        }
        .frame(minWidth: 0, maxWidth: .infinity)
        .padding()
        .background(.ultraThinMaterial)
    }
}

struct SumbitBottomButton_Previews: PreviewProvider {
    static var previews: some View {
        List {
            SubmitBottomButton(text: "TEST", enableButton: .constant(false), isLoading: .constant(false)) {

            }
            SubmitBottomButton(text: "TEST", enableButton: .constant(true), isLoading: .constant(true)) {

            }
            SubmitBottomButton(text: "TEST", enableButton: .constant(true), isLoading: .constant(false)) {

            }
        }
        .safeAreaInset(edge: .bottom) {
            SubmitBottomButton(text: "TEST", enableButton: .constant(true), isLoading: .constant(false)) {
            }
        }
    }
}
