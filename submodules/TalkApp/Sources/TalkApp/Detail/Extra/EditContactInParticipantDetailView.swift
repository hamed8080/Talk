//
//  EditContactInParticipantDetailView.swift
//  Talk
//
//  Created by hamed on 5/6/24.
//

import SwiftUI
import TalkViewModels
import TalkUI
import TalkModels
import Chat

struct EditContactInParticipantDetailView: View {
    @EnvironmentObject var viewModel: ParticipantDetailViewModel
    @State private var contactValue: String = ""
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @Environment(\.dismiss) private var dismiss
    private var editContact: Contact? { viewModel.partnerContact }
    @FocusState private var focusState: ContactFocusFileds?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                TextField("General.firstName".bundleLocalized(), text: $firstName)
                    .focused($focusState, equals: .firstName)
                    .textContentType(.name)
                    .submitLabel(.done)
                    .padding()
                    .applyAppTextfieldStyle(topPlaceholder: "General.firstName", isFocused: focusState == .firstName) {
                        focusState = .firstName
                    }
                TextField(optioanlAppend(text: "General.lastName".bundleLocalized()), text: $lastName)
                    .focused($focusState, equals: .lastName)
                    .textContentType(.familyName)
                    .submitLabel(.done)
                    .padding()
                    .applyAppTextfieldStyle(topPlaceholder: "General.lastName", isFocused: focusState == .lastName) {
                        focusState = .lastName
                    }
                TextField("Contacts.Add.phoneOrUserName".bundleLocalized(), text: $contactValue)
                    .focused($focusState, equals: .contactValue)
                    .keyboardType(.default)
                    .submitLabel(.done)
                    .padding()
                    .applyAppTextfieldStyle(topPlaceholder: "Contacts.Add.phoneOrUserName", error: nil, isFocused: focusState == .contactValue) {
                        focusState = .contactValue
                    }
                    .disabled(true)
                    .opacity(0.3)
                if !isLargeSize {
                    Spacer()
                }
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            toolbarView
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            let title = "Contacts.Edit.title"
            SubmitBottomButton(text: title, enableButton: .constant(enableButton), isLoading: $viewModel.isLoading) {
                submit()
            }
        }
        .animation(.easeInOut, value: enableButton)
        .animation(.easeInOut, value: focusState)
        .font(Font.normal(.body))
        .onChange(of: viewModel.successEdited) { newValue in
            if newValue == true {
                withAnimation {
                    dismiss()
                }
            }
        }
        .onTapGesture {
            hideKeyboard()
        }
        .onAppear {
            firstName = editContact?.firstName ?? ""
            lastName = editContact?.lastName ?? ""
            contactValue = editContact?.computedUserIdentifire ?? ""
            focusState = .firstName
            viewModel.successEdited = false
        }
    }

    private var isLargeSize: Bool {
        let mode = UIApplication.shared.windowMode()
        if mode == .ipadFullScreen || mode == .ipadHalfSplitView || mode == .ipadTwoThirdSplitView {
            return true
        } else {
            return false
        }
    }

    private var enableButton: Bool {
        !firstName.isEmpty && !contactValue.isEmpty && !viewModel.isLoading
    }

    func submit() {
        /// Add or edit use same method.
        viewModel.editContact(contactValue: contactValue, firstName: firstName, lastName: lastName)
    }

    func optioanlAppend(text: String) -> String {
        "\(text.bundleLocalized()) \("General.optional".bundleLocalized())"
    }

    var toolbarView: some View {
        VStack(spacing: 0) {
            ToolbarView(title: "Contacts.Edit.title",
                        showSearchButton: false,
                        leadingViews: leadingViews,
                        centerViews: EmptyView(),
                        trailingViews: EmptyView()) {_ in }
        }
    }

    var leadingViews: some View {
        NavigationBackButton(automaticDismiss: true) {}
    }
}

struct EditContactInParticipantDetailView_Previews: PreviewProvider {
    static var previews: some View {
        EditContactInParticipantDetailView()
    }
}
