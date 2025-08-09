//
//  AddOrEditContactView.swift
//  Talk
//
//  Created by Hamed Hosseini on 9/23/21.
//

import Chat
import SwiftUI
import TalkViewModels
import TalkUI
import TalkModels

enum ContactType: String, Identifiable, CaseIterable {
    var id: Self { self }
    case phoneNumber
    case userName
}

enum ContactFocusFileds: Hashable {
    case contactValue
    case firstName
    case lastName
    case submit
}

@available(iOS 16.4, macOS 13.3, tvOS 16.4, watchOS 9.4, *)
struct AddOrEditContactView: View {
    @State var contactValue: String = ""
    @State var firstName: String = ""
    @State var lastName: String = ""
    var showToolbar: Bool = false
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var viewModel: ContactsViewModel
    var addContact: Contact? { viewModel.addContact }
    var editContact: Contact? { viewModel.editContact }
    @FocusState var focusState: ContactFocusFileds?
    var isInEditMode: Bool { addContact == nil && editContact != nil }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if !showToolbar {
                    Text(isInEditMode ? "Contacts.Edit.title" : "Contacts.Add.title")
                        .font(.fBoldSubtitle)
                        .padding()
                        .offset(y: 24)
                }
                TextField("General.firstName".bundleLocalized(), text: $firstName)
                    .focused($focusState, equals: .firstName)
                    .textContentType(.name)
                    .submitLabel(.next)
                    .padding()
                    .applyAppTextfieldStyle(topPlaceholder: "General.firstName", isFocused: focusState == .firstName) {
                        focusState = .firstName
                    }
                TextField(optioanlAPpend(text: "General.lastName".bundleLocalized()), text: $lastName)
                    .focused($focusState, equals: .lastName)
                    .textContentType(.familyName)
                    .submitLabel(.next)
                    .padding()
                    .applyAppTextfieldStyle(topPlaceholder: "General.lastName", isFocused: focusState == .lastName) {
                        focusState = .lastName
                    }
                TextField("Contacts.Add.phoneOrUserName".bundleLocalized(), text: $contactValue)
                    .focused($focusState, equals: .contactValue)
                    .keyboardType(.default)
                    .submitLabel(.done)
                    .padding()
                    .applyAppTextfieldStyle(topPlaceholder: "Contacts.Add.phoneOrUserName", error: viewModel.userNotFound ? "Contctas.notFound" : nil, isFocused: focusState == .contactValue) {
                        focusState = .contactValue
                    }
                    .disabled(isInEditMode)
                    .opacity(isInEditMode ? 0.3 : 1)
                if !isLargeSize {
                    Spacer()
                }
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            if showToolbar {
                toolbarView
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            let title = isInEditMode ? "Contacts.Edit.title" : "Contacts.Add.title"
            SubmitBottomButton(text: title, enableButton: .constant(enableButton), isLoading: $viewModel.lazyList.isLoading) {
                Task {
                    await submit()
                }
            }
        }
        .presentationDetents([.fraction((isLargeSize ? 100 : 70) / 100)])
        .presentationBackground(.ultraThinMaterial)
        .presentationDragIndicator(.visible)
        .animation(.easeInOut, value: enableButton)
        .animation(.easeInOut, value: focusState)
        .animation(.easeInOut, value: viewModel.userNotFound)
        .font(.fBody)
        .onChange(of: viewModel.successAdded) { newValue in
            if newValue == true {
                withAnimation {
                    dismiss()
                }
            }
        }
        .onChange(of: contactValue) { [contactValue] newValue in
            if newValue.count != contactValue.count, viewModel.userNotFound {
                withAnimation {
                    viewModel.userNotFound = false
                }
            }
        }
        .onTapGesture {
            hideKeyboard()
        }
        .onAppear {
            let contact = isInEditMode ? editContact : addContact
            firstName = contact?.firstName ?? ""
            lastName = contact?.lastName ?? ""
            contactValue = contact?.computedUserIdentifire ?? ""
            focusState = .firstName
            viewModel.successAdded = false
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
        !firstName.isEmpty && !contactValue.isEmpty && !viewModel.lazyList.isLoading
    }

    func submit() async {
        /// Add or edit use same method.
        await viewModel.addContact(contactValue: contactValue, firstName: firstName, lastName: lastName)
    }

    func optioanlAPpend(text: String) -> String {
        "\(text.bundleLocalized()) \("General.optional".bundleLocalized())"
    }

    var toolbarView: some View {
        VStack(spacing: 0) {
            ToolbarView(title: isInEditMode ? "Contacts.Edit.title" : "Contacts.Add.title",
                        showSearchButton: false,
                        leadingViews: leadingTralingView,
                        centerViews: EmptyView(),
                        trailingViews: EmptyView()) {_ in }
        }
    }

    var leadingTralingView: some View {
        NavigationBackButton(automaticDismiss: true) {}
    }
}

@available(iOS 16.4, macOS 13.3, tvOS 16.4, watchOS 9.4, *)
struct AddOrEditContactView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            AddOrEditContactView()
                .environmentObject(ContactsViewModel())
        }
    }
}
