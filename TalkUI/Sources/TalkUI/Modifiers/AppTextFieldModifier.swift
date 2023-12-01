//
//  SwiftUIView.swift
//  
//
//  Created by hamed on 10/19/23.
//

import SwiftUI

public struct AppTextFieldModifier: ViewModifier {
    let topPlaceholder: String
    let innerBGColor: Color
    let error: String?
    let minHeigh: CGFloat
    let isFocused: Bool
    /// We use onClick for the border around where they are not clickable.
    let onClick: (() -> Void)?

    public func body(content: Content) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(String(localized: .init(topPlaceholder)))
                .font(.iransansCaption)
                .padding(.horizontal, 20)
                .offset(y: 8)
            content
                .frame(minHeight: minHeigh)
                .background(isFocused ? Color.clear : innerBGColor)
                .overlay(alignment: .center) {
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(error != nil ? Color.App.red : isFocused ? Color.App.primary : Color.clear, lineWidth: 2)
                        .frame(minHeight: minHeigh)
                }
                .clipShape(RoundedRectangle(cornerRadius:(12)))
                .padding()
                .onTapGesture {
                    onClick?()
                }

            if let error {
                Text(String(localized: .init(error)))
                    .font(.iransansCaption)
                    .padding(.horizontal, 20)
                    .offset(y: -8)
                    .foregroundColor(Color.App.red)
            }
        }
    }
}

public extension View {
    func applyAppTextfieldStyle(topPlaceholder: String = "", innerBGColor: Color = Color.App.bgInput, error: String? = nil, minHeight: CGFloat = 52, isFocused: Bool = false, onClick: (() -> Void)? = nil) -> some View {
        modifier(AppTextFieldModifier(topPlaceholder: topPlaceholder, innerBGColor: innerBGColor, error: error, minHeigh: minHeight, isFocused: isFocused, onClick: onClick))
    }
}

struct AppTextFieldModifier_Previews: PreviewProvider {
    struct Preview: View {
        enum AppTextFieldModifierTestFileds: Hashable {
            case firstName
        }

        @FocusState var focusState: AppTextFieldModifierTestFileds?

        var body: some View {
            TextField("Contacts.Add.firstName", text: .constant("Value"))
                .focused($focusState, equals: .firstName)
                .keyboardType(.default)
                .padding()
                .applyAppTextfieldStyle(topPlaceholder: "Contacts.Add.phoneOrUserName", isFocused: focusState == .firstName) {
                    focusState = .firstName
                }
        }

    }
    static var previews: some View {
        VStack {
            Preview()
        }
        .background(Color.App.purple)
    }
}
