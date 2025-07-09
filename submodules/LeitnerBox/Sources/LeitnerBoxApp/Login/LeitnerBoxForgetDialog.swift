//
//  LeitnerBoxForgetDialog.swift
//  LeitnerBoxApp
//
//  Created by Hamed Hosseini on 5/6/25.
//

import Foundation
import SwiftUI

struct LeitnerBoxForgetDialog: View {
    @EnvironmentObject var viewModel: LeitnerBoxForgetViewModel
    enum Field: Hashable {
        case email
    }
    @FocusState var focusedField: Field?
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(alignment: .center, spacing: 16) {
            Spacer()
            Group {
                Text("Forget")
                    .font(.title.bold())
                    .foregroundColor(Color.primary)

                TextField("Email", text: $viewModel.email)
                    .focused($focusedField, equals: .email)
                    .keyboardType(.emailAddress)
                    .font(.body)
                    .padding()
                    .frame(maxWidth: 420)
                    .overlay(alignment: .center) {
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(viewModel.state == .failed ? Color.red : focusedField == .email ? Color.accentColor : Color.gray.opacity(0.7), lineWidth: 2)
                            .frame(minHeight: 52)
                    }
                    .clipShape(RoundedRectangle(cornerRadius:(12)))

                if viewModel.state == .failed {
                    Text("Failed to send forget password request!")
                        .padding(.horizontal)
                        .foregroundStyle(.red)
                }
            }

            Spacer()

            Button {
                withAnimation {
                    viewModel.requestForgetPassword()
                }
            } label: {
                HStack(spacing: 8) {
                    Spacer()
                    Text("Send email")
                        .font(.body)
                        .contentShape(Rectangle())
                        .foregroundStyle(Color.primary)
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(.circular)
                    }
                    Spacer()
                }
                .frame(minWidth: 0, maxWidth: 420)
                .contentShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
            .frame(height: 48)
            .contentShape(RoundedRectangle(cornerRadius: 8))
            .background(Color.accentColor)
            .clipShape(RoundedRectangle(cornerRadius:(8)))
            .disabled(viewModel.isLoading)
            .opacity(!viewModel.isLoading ? 1.0 : 0.3)
        }
        .environment(\.layoutDirection, .leftToRight)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .overlay(alignment: .topLeading) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
            }
            .frame(width: 48, height: 48)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .padding()
        }
        .animation(.easeInOut, value: focusedField)
        .onChange(of: viewModel.state) { newState in
            if newState == .success {
                dismiss()
            }
        }
        .onTapGesture {
            hideKeyboard()
        }
        .onAppear {
            focusedField = .email
        }
    }
}

