//
//  OTPNumbers.swift
//  Talk
//
//  Created by hamed on 5/8/24.
//

import SwiftUI
import TalkViewModels
import AdditiveUI
import TalkUI

fileprivate enum VerifyFocusFileds: Int, Hashable, CaseIterable {
    case first = 0
    case second = 1
    case third = 2
    case fourth = 3
    case fifth = 4
    case sixth = 5
}

struct OTPNumbers: View {
    @EnvironmentObject var viewModel: LoginViewModel
    @FocusState fileprivate var focusField: VerifyFocusFileds?

    var body: some View {
        HStack(spacing: 16) {
            ForEach(0 ..< VerifyFocusFileds.allCases.endIndex, id: \.self) { i in
                TextField("", text: $viewModel.verifyCodes[i])
                    .frame(minHeight: 56)
                    .textFieldStyle(borderStyle)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .font(Font.bold(.largeTitle))
                    .focused($focusField, equals: VerifyFocusFileds.allCases.first(where: { i == $0.rawValue })!)
                    .disabled(viewModel.isLoading)
                    .opacity(viewModel.isLoading && !viewModel.showSuccessAnimation ? 0.5 : 1)
                    .onChange(of: viewModel.verifyCodes[i]) { newString in
                        onTextChangedInFiledWith(index: i, newString)
                    }
            }
        }
        .animation(.smooth, value: viewModel.showSuccessAnimation)
        .onAppear {
            focusField = VerifyFocusFileds.first
        }
    }

    private var borderStyle: some TextFieldStyle {
        BorderedTextFieldStyle(minHeight: 56,
                               cornerRadius: 12,
                               bgColor: Color.App.bgInput,
                               borderColor: viewModel.showSuccessAnimation ? Color.App.color2 : Color.clear,
                               padding: 0)
    }

    private func setVerifyCodes(_ integers: [Int]) {
        viewModel.verifyCodes = integers.map({"\($0)"})
    }

    private func getIntegers(_ newString: String) -> [Int]? {
        var intArray: [Int] = []
        for ch in newString {
            let intVal = Int("\(ch)")
            if let intVal = intVal {
                intArray.append(intVal)
            } else {
                break
            }
        }
        if intArray.count == 0 { return nil }
        return intArray
    }

    private func onAutomaticVerify() {
        // Submit automatically
        // After the user clicked on the sms we have to make sure that the last filed is selected
        focusField = .sixth
        // We wait 500 millisecond to fill out all text fields if the user clicked on sms
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            Task {
                await viewModel.verifyCode()
            }
        }
    }

    private func onTextChangedInFiledWith(index i: Int, _ newString: String) {
        if newString.count == viewModel.verifyCodes.count, let integers = getIntegers(newString) {
            setVerifyCodes(integers)
            return
        }

        if newString.count > 2, i == VerifyFocusFileds.allCases.count - 1 {
            viewModel.verifyCodes[i] = String(newString[newString.startIndex..<newString.index(newString.startIndex, offsetBy: 2)])
            return
        }

        if !newString.hasPrefix("\u{200B}") {
            viewModel.verifyCodes[i] = "\u{200B}" + newString
        }

        if newString.count == 0 && i == 0 {
            viewModel.verifyCodes[0] = ""
        }

        if newString.count == 0 , i > 0 {
            viewModel.verifyCodes[i - 1] = "\u{200B}"
            focusField = VerifyFocusFileds.allCases.first(where: { $0.rawValue == i - 1 })
        }

        /// Move focus to the next textfield if there is something inside the textfield.
        if viewModel.verifyCodes[i].count == 2, i < VerifyFocusFileds.allCases.count - 1 {
            if viewModel.verifyCodes[i + 1].count == 0 {
                viewModel.verifyCodes[i + 1] = "\u{200B}"
            }
            focusField = VerifyFocusFileds.allCases.first(where: { $0.rawValue == i + 1 })
        }

        if viewModel.verifyCodes[i].count == 2, i == VerifyFocusFileds.allCases.count - 1 {
            onAutomaticVerify()
        }
    }
}

struct OTPNumbers_Previews: PreviewProvider {
    static var previews: some View {
        OTPNumbers()
    }
}
