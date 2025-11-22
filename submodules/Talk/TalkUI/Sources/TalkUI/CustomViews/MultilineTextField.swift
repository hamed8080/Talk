//
//  MultilineTextField.swift
//  TalkUI
//
//  Created by Hamed Hosseini on 10/7/21.
//

import SwiftUI

private struct UITextViewWrapper: UIViewRepresentable {
    typealias UIViewType = UITextView
    private let font = UIFont.normal(.subheadline)

    @Binding var text: String
    var textColor: UIColor
    @Binding var calculatedHeight: CGFloat
    @Binding var focus: Bool
    var keyboardReturnType: UIReturnKeyType = .done
    var mention: Bool = false
    var onDone: ((String?) -> Void)?

    func makeUIView(context: UIViewRepresentableContext<UITextViewWrapper>) -> UITextView {
        let textField = UITextView()
        textField.delegate = context.coordinator

        textField.isEditable = true
        textField.font = font
        textField.isSelectable = true
        textField.isUserInteractionEnabled = true
        textField.isScrollEnabled = true
        textField.backgroundColor = UIColor.clear
        textField.textColor = textColor
        textField.returnKeyType = keyboardReturnType
        textField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return textField
    }

    func updateUIView(_ uiView: UITextView, context _: UIViewRepresentableContext<UITextViewWrapper>) {
        if uiView.text != text {
            let attributes = NSMutableAttributedString(string: text)
            if mention {
                text.matches(char: "@")?.forEach { match in
                    attributes.addAttributes([NSAttributedString.Key.foregroundColor: UIColor(named: "blue") ?? .blue, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16)], range: match.range)
                }
                uiView.attributedText = attributes
            } else {
                uiView.text = text
            }
            uiView.font = font
            uiView.textColor = textColor
        }
        if focus {
            uiView.becomeFirstResponder()
        }
        recalculateHeight(view: uiView)
    }

    fileprivate func recalculateHeight(view: UITextView) {
        let oldHeightValue = calculatedHeight
        let width = view.frame.size.width
        let text = view.text ?? ""
        Task.detached(priority: .userInitiated) {
            let newHeight = await sizeForString(attributes(string: text), width: width).height + 18
            let MIN: CGFloat = 42
            let MAX: CGFloat = 256
            let height = max(min(MAX, newHeight), MIN)
            if oldHeightValue != height {
                await MainActor.run {
                    calculatedHeight = height // !! must be called asynchronously
                }
            }
        }
    }

    nonisolated private func sizeForString(_ str : NSAttributedString, width : CGFloat) -> CGSize {
        let ts = NSTextStorage(attributedString: str)

        let size = CGSize(width: width, height: .greatestFiniteMagnitude)

        let tc = NSTextContainer(size: size)
        tc.lineFragmentPadding = 5.0

        let lm = NSLayoutManager()
        lm.addTextContainer(tc)

        ts.addLayoutManager(lm)
        lm.glyphRange(forBoundingRect: CGRect(origin: .zero, size: size), in: tc)

        let rect = lm.usedRect(for: tc)

        return rect.size
    }

    nonisolated private func attributes(string: String) -> NSAttributedString {
        let mutableAttr = NSMutableAttributedString(string: string)
        let attributes = [NSAttributedString.Key.font: font]
        let allRange = NSRange(mutableAttr.string.startIndex..., in: mutableAttr.string)
        mutableAttr.addAttributes(attributes, range: allRange)
        return mutableAttr
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, wrapper: self, onDone: onDone)
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        var text: Binding<String>
        var onDone: ((String?) -> Void)?
        private var wrapper: UITextViewWrapper

        init(text: Binding<String>, wrapper: UITextViewWrapper, onDone: ((String?) -> Void)? = nil) {
            self.text = text
            self.onDone = onDone
            self.wrapper = wrapper
        }

        func textViewDidChange(_ uiView: UITextView) {
            text.wrappedValue = uiView.text
            wrapper.recalculateHeight(view: uiView)
        }

        func textView(_ textView: UITextView, shouldChangeTextIn _: NSRange, replacementText text: String) -> Bool {
            if let onDone = onDone, text == "\n" {
                textView.resignFirstResponder()
                onDone(textView.text)
                return false
            }
            return true
        }
    }
}

public struct MultilineTextField: View {
    private var placeholder: String
    private var onDone: ((String?) -> Void)?
    var backgroundColor: Color = .white
    var placeholderColor: Color = Color.App.textPlaceholder
    var textColor: UIColor?
    @Environment(\.colorScheme) var colorScheme
    var keyboardReturnType: UIReturnKeyType = .default
    var mention: Bool = false
    private var disable: Bool

    @Binding private var text: String
    @Binding private var focus: Bool
    @State private var dynamicHeight: CGFloat = 42
    @State private var showingPlaceholder = false

    public init(_ placeholder: String = "",
         text: Binding<String>,
         textColor: UIColor? = nil,
         backgroundColor: Color = Color.App.white,
         placeholderColor: Color = Color.App.textPlaceholder,
         keyboardReturnType: UIReturnKeyType = .default,
         mention: Bool = false,
         focus: Binding<Bool> = .constant(false),
         disable: Bool = false,
         onDone: ((String?) -> Void)? = nil)
    {
        self.placeholder = placeholder
        self.onDone = onDone
        self.textColor = textColor
        _text = text
        self.backgroundColor = backgroundColor
        self.keyboardReturnType = keyboardReturnType
        self.mention = mention
        self._focus = focus
        self.placeholderColor = placeholderColor
        let canShowPlaceHolder = text.wrappedValue.isEmpty || (text.wrappedValue.first == "\u{200f}" && text.wrappedValue.count == 1)
        self.disable = disable
        _showingPlaceholder = State<Bool>(initialValue: canShowPlaceHolder)
    }

    public var body: some View {
        UITextViewWrapper(text: $text,
                          textColor: textColor ?? (colorScheme == .dark ? UIColor(named: "white") ?? .white : UIColor(named: "black") ?? .black),
                          calculatedHeight: $dynamicHeight,
                          focus: $focus,
                          keyboardReturnType: keyboardReturnType,
                          mention: mention,
                          onDone: onDone)
            .frame(height: disable ? 0 : dynamicHeight)
            .padding(.horizontal, 4)
            .background(placeholderView, alignment: .topLeading)
            .background(backgroundColor)
            .onChange(of: text) { newValue in
                withAnimation(.easeInOut(duration: 0.2)) {
                    showingPlaceholder = newValue.isEmpty || (newValue.first == "\u{200f}" && newValue.count == 1)
                }
            }
    }

    var placeholderView: some View {
        Group {
            if showingPlaceholder {
                Text(placeholder)
                    .font(Font.normal(.body))
                    .foregroundColor(placeholderColor)
                    .padding(EdgeInsets(top: 8, leading: 12, bottom: 0, trailing: 0))
                    .transition(.asymmetric(insertion: .push(from: .leading), removal: .move(edge: .leading)))
            }
        }
    }
}

#if DEBUG
    struct MultilineTextField_Previews: PreviewProvider {
        private struct Preview: View {
            @State private var test: String = ""
            
            var body: some View {
                VStack(alignment: .leading) {
                    Text("Description:")
                    MultilineTextField("Enter some text here", text: $test, keyboardReturnType: .search, onDone: { _ in })
                        .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.App.textPrimary))
                    Text("Something static here...")
                    Spacer()
                }
                .padding()
            }
        }

        static var previews: some View {
            Preview()
        }
    }
#endif
