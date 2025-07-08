//
//  LeitnerBoxLoginDialog.swift
//  LeitnerBoxApp
//
//  Created by Hamed Hosseini on 5/6/25.
//

import Foundation
import SwiftUI

struct LeitnerBoxLoginDialog: View {
    @EnvironmentObject var viewModel: LeitnerBoxLoginViewModel
    enum Field: Hashable {
        case username
        case password
    }
    
    @FocusState var focusedField: Field?
    @Binding var showRegister: Bool
    @Binding var showForget: Bool
    @Binding var showDeleteAccount: Bool
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(alignment: .center, spacing: 16) {
            Spacer()
            Group {
                Text("Login Or Register")
                    .font(.title.bold())
                    .foregroundColor(Color.primary)

                TextField("Username", text: $viewModel.username)
                    .focused($focusedField, equals: .username)
                    .keyboardType(.default)
                    .font(.body)
                    .padding()
                    .frame(maxWidth: 420)
                    .overlay(alignment: .center) {
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(viewModel.state == .failed ? Color.red : focusedField == .username ? Color.accentColor : Color.gray.opacity(0.7), lineWidth: 2)
                            .frame(minHeight: 52)
                    }
                    .clipShape(RoundedRectangle(cornerRadius:(12)))
                
                SecureField("Password", text: $viewModel.password)
                    .focused($focusedField, equals: .password)
                    .keyboardType(.default)
                    .font(.body)
                    .padding()
                    .frame(maxWidth: 420)
                    .overlay(alignment: .center) {
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(viewModel.state == .failed ? Color.red : focusedField == .password ? Color.accentColor : Color.gray.opacity(0.7), lineWidth: 2)
                            .frame(minHeight: 52)
                    }
                    .clipShape(RoundedRectangle(cornerRadius:(12)))
                
                HStack(spacing: 8) {
                    Button {
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                            showRegister = true
                        }
                    } label: {
                        Text("Register")
                            .font(.subheadline)
                            .foregroundStyle(.blue)
                    }
                    Rectangle()
                        .fill(Color.gray.opacity(0.5))
                        .frame(width: 1, height: 28)
                    Button {
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                            showForget = true
                        }
                    } label: {
                        Text("Forget?")
                            .font(.subheadline)
                            .foregroundStyle(.blue)
                    }
                    Rectangle()
                        .fill(Color.gray.opacity(0.5))
                        .frame(width: 1, height: 28)
                    Button {
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                            showDeleteAccount = true
                        }
                    } label: {
                        Text("Delete Account")
                            .font(.subheadline)
                            .foregroundStyle(.blue)
                    }
                }
                .frame(height: 48)
                
                if viewModel.state == .failed {
                    Text("Failed to logged in, something went wrong! \n make sure user name and password is correct")
                        .padding(.horizontal)
                        .foregroundStyle(.red)
                }
            }

            Spacer()

            Button {
                withAnimation {
                    viewModel.login()
                }
            } label: {
                HStack(spacing: 8) {
                    Spacer()
                    Text("Login")
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
        .onChange(of: viewModel.state) { newState in
            if newState == .success {
                dismiss()
            }
        }
        .onTapGesture {
            hideKeyboard()
        }
        .onAppear {
            focusedField = .username
        }
    }
}
