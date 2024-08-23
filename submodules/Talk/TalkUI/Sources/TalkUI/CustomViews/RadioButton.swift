//
//  RadioButton.swift
//  TalkUI
//
//  Created by hamed on 2/20/22.
//

import SwiftUI

public struct RadioButton: View {
    @Binding var visible: Bool
    @Binding var isSelected: Bool
    var action: ((Bool) -> Void)?

    public init(visible: Binding<Bool>, isSelected: Binding<Bool>, action: ((Bool) -> Void)? = nil) {
        self._visible = visible
        self._isSelected = isSelected
        self.action = action
    }

    public var body: some View {
        ZStack {
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .resizable()
                .scaledToFit()
                .font(.title)
                .foregroundStyle(isSelected ? Color.App.white : Color.App.textSecondary, isSelected ? Color.App.accent : Color.App.textSecondary)
                .overlay(alignment: .center) {
                    Circle()
                        .stroke(isSelected ? Color.App.white : Color.clear, lineWidth: 1)
                }
        }
        .frame(width: visible ? 22 : 0.001, height: visible ? 22 : 0.001, alignment: .center)        
        .scaleEffect(x: visible ? 1.0 : 0.001, y: visible ? 1.0 : 0.001, anchor: .center)
        .onTapGesture {
            withAnimation(!isSelected ? .spring(response: 0.4, dampingFraction: 0.3, blendDuration: 0.3) : .linear) {
                action?(isSelected)
            }
        }
    }
}

struct RadioButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            RadioButton(visible: .constant(true), isSelected: .constant(true)) { _ in }
            RadioButton(visible: .constant(true), isSelected: .constant(false)) { _ in }
        }
    }
}
