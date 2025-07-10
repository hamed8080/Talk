//
//  LeitnerBoxDeleteAccountDialog.swift
//  LeitnerBoxApp
//
//  Created by Hamed Hosseini on 5/29/25.
//

import Foundation
import SwiftUI

struct LeitnerBoxDeleteAccountDialog: View {
    @EnvironmentObject var viewModel: LeitnerBoxDeleteAccountViewModel
    enum Field: Hashable {
        case email
        case password
    }
    @FocusState var focusedField: Field?
    @Environment(\.dismiss) var dismiss
    @State private var showWarningView: Bool = true
    
    var body: some View {
        if showWarningView {
            warningView
                .transition(.push(from: .leading))
        } else {
            normalDeleteView
                .transition(.push(from: .trailing))
        }
    }
    
    @ViewBuilder
    private var normalDeleteView: some View {
        VStack(alignment: .center, spacing: 16) {
            Spacer()
            Group {
                Text("Delete Account")
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
                
                TextField("Password", text: $viewModel.password)
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
                
                if viewModel.state == .failed {
                    Text("Failed to remove the account, try again")
                        .padding(.horizontal)
                        .foregroundStyle(.red)
                }
                if viewModel.state == .success {
                    Text("Your account has been deleted successfully.")
                        .padding(.horizontal)
                        .foregroundStyle(.green)
                }
            }
            
            Spacer()
            
            Button {
                withAnimation {
                    viewModel.deleteAccount()
                }
            } label: {
                HStack(spacing: 8) {
                    Spacer()
                    Label("Delete Account", systemImage: "person.crop.circle.badge.minus")
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(.circular)
                    }
                    Spacer()
                }
                .frame(minWidth: 0, maxWidth: 420)
                .contentShape(RoundedRectangle(cornerRadius: 8))
            }
            .frame(height: 22)
            .padding()
            .cornerRadius(6)
            .background(Color.red.opacity(0.09).cornerRadius(12))
            .foregroundColor(Color.red)
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.red, lineWidth: 1)
            }
        }
        .environment(\.layoutDirection, .leftToRight)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .overlay(alignment: .topLeading) {
            dismissButton
        }
        .animation(.easeInOut, value: focusedField)
        .onTapGesture {
            hideKeyboard()
        }
        .onAppear {
            focusedField = .email
        }
    }
    
    @ViewBuilder
    private var warningView: some View {
        ScrollView {
            HStack {
                Spacer()
                let deleteText = """
• This action is irreversible.
• All data will be lost, including:
    • Your user account
    • Your suggested words
    • Your profile
"""
                Text(deleteText)
                    .font(.title.weight(.semibold))
                    .environment(\.layoutDirection, .leftToRight)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(24)
                Spacer()
            }
            .padding()
            .padding(.top, 64)
        }
        .overlay(alignment: .topLeading) {
            dismissButton
        }
        .overlay(alignment: .bottom) {
            HStack {
                Button {
                    withAnimation {
                        self.showWarningView = false
                    }
                } label: {
                    HStack(spacing: 8) {
                        Spacer()
                        Label("I am sure, Proceed", systemImage: "person.crop.circle.badge.minus")
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(.circular)
                        }
                        Spacer()
                    }
                    .frame(minWidth: 0, maxWidth: 420)
                    .contentShape(RoundedRectangle(cornerRadius: 8))
                }
                .frame(height: 22)
                .padding()
                .cornerRadius(6)
                .background(Color.red.opacity(0.09).cornerRadius(12))
                .foregroundColor(Color.red)
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.red, lineWidth: 1)
                }
            }
            .padding()
        }
    }
    
    private var dismissButton: some View {
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
}
