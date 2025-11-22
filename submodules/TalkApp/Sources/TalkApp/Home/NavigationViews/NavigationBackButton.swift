//
//  NavigationBackButton.swift
//  Talk
//
//  Created by hamed on 10/5/23.
//

import SwiftUI
import TalkViewModels

public struct NavigationBackButton: View {
    @EnvironmentObject var navViewModel: NavigationModel
    @Environment(\.dismiss) var dismiss
    let action: (() -> ())?
    @GestureState private var isTouching = false
    private let automaticDismiss: Bool

    public init(automaticDismiss: Bool, action: (() -> Void)? = nil) {
        self.automaticDismiss = automaticDismiss
        self.action = action
    }

    public var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "chevron.backward")
                .resizable()
                .scaledToFit()
                .padding(EdgeInsets(top: 12, leading: 0, bottom: 14, trailing: navViewModel.previousTitle.isEmpty ? 8 : 2))
                .fontWeight(.medium)
        }
        .foregroundColor(Color.App.toolbarButton)
        .background(Color.clear)
        .frame(minWidth: ToolbarButtonItem.buttonWidth, minHeight: ToolbarButtonItem.buttonWidth)
        .contentShape(Rectangle())
        .gesture(tapGesture.simultaneously(with: touchDownGesture))
        .opacity(isTouching ? 0.5 : 1.0)
    }

    var touchDownGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .updating($isTouching) { value, state, transaction in
                transaction.animation = .easeInOut
                state = true
            }
    }

    var tapGesture: some Gesture {
        TapGesture(count: 1)
            .onEnded { _ in
                action?()
                if automaticDismiss {
                    dismiss()
                }
            }
    }
}

public struct NormalNavigationBackButton: View {
    @Environment(\.dismiss) var dismiss

    public init() {}

    public var body: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.backward")
                        .resizable()
                        .scaledToFit()
                        .fontWeight(.medium)
                        .frame(maxWidth: 16, maxHeight: 16)
                    Text("General.back")
                        .font(Font.normal(.body))
                }
            }
            Spacer()
        }
        .padding(16)
        .background(.ultraThinMaterial)        
    }
}

struct NavigationBackButton_Previews: PreviewProvider {
    static var previews: some View {
        NavigationBackButton(automaticDismiss: true) {}
    }
}
