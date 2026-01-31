//
//  TalkBackProxyView.swift
//  Talk
//
//  Created by Hamed Hosseini on 12/15/24.
//

import SwiftUI
import TalkUI
import TalkViewModels
import Spec

struct TalkBackProxyView: View {
    @EnvironmentObject var viewModel: TalkBackProxyViewModel
    
    var body: some View {
        List {
            TalkBackProxyRow()
                .listRowInsets(.zero)
                .listRowBackground(Color.App.bgPrimary)
                .listRowSeparatorTint(Color.App.dividerPrimary)
        }
        .font(Font.normal(.body))
        .environment(\.defaultMinListRowHeight, 8)
        .listStyle(.plain)
        .background(Color.App.bgPrimary)
        .normalToolbarView(title: "Settings.connectionSettings", type: String.self)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            SubmitBottomButton(text: "General.done", enableButton: Binding(get: { !viewModel.isLoading }, set: { _ in }), isLoading: $viewModel.isLoading) {
                Task {
                    do {
                        try await viewModel.submit()
                    } catch {
                       var i = error
                    }
                }
            }
        }
    }
}

struct TalkBackProxyRow: View {
    private enum ProxyFocusFileds: Hashable {
        case proxyAddress
    }
    @FocusState private var focusState: ProxyFocusFileds?
    @EnvironmentObject var viewModel: TalkBackProxyViewModel

    var body: some View {
        HStack {
            VStack {
                let staticText = "Settings.proxyAddress".bundleLocalized()
                HStack {
                    Text(staticText)

                    Spacer()
                    
                    Toggle("", isOn: $viewModel.isProxyMode)
                        .tint(Color.App.accent)
                        .frame(maxWidth: 64)
                }
                .multilineTextAlignment(Language.isRTL ? .leading : .trailing)
                .padding([.leading, .top, .trailing], 16)

                if viewModel.isProxyMode {
                    TextField(staticText, text: $viewModel.talkBackProxyAddress)
                        .focused($focusState, equals: .proxyAddress)
                        .textContentType(.familyName)
                        .submitLabel(.next)
                        .padding()
                        .applyAppTextfieldStyle(topPlaceholder: "", error: viewModel.error, isFocused: focusState == .proxyAddress) {
                            focusState = .proxyAddress
                        }
                        .disabled(viewModel.isLoading)
                        .opacity(viewModel.isLoading ? 0.3 : 1)
                }
            }
            .frame(minWidth: 0, maxWidth: .infinity)
        }
    }
}

#Preview {
    TalkBackProxyView()
}
