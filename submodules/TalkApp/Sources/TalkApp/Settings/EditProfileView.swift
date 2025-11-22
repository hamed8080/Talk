//
//  EditProfileView.swift
//  Talk
//
//  Created by hamed on 12/1/23.
//

import SwiftUI
import TalkViewModels
import TalkUI
import TalkModels
import Photos

enum EditProfileFocusFileds: Hashable {
    case firstName
    case lastName
    case userName
    case bio
}

struct EditProfileView: View {
    @StateObject var viewModel: EditProfileViewModel = .init()
    @FocusState var focusedField: EditProfileFocusFileds?
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .center, spacing: 16) {
                Button {
//                    viewModel.showImagePicker = true
                } label: {
                    ZStack(alignment: .leading) {
                        ImageLoaderView(user: AppState.shared.user)
                            .scaledToFit()
                            .font(Font.bold(.caption2))
                            .foregroundColor(.white)
                            .frame(width: 100, height: 100)
                            .background(Color(uiColor: String.getMaterialColorByCharCode(str: AppState.shared.user?.name ?? "")))
                            .clipShape(RoundedRectangle(cornerRadius:(44)))
                            .overlay(alignment: .center) {
                                /// Showing the image taht user has selected.
                                if let image = viewModel.image {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 100, height: 100)
                                        .clipShape(RoundedRectangle(cornerRadius:(44)))
                                }
                            }
                        Circle()
                            .fill(.red)
                            .frame(width: 28, height: 28)
                            .offset(x: 68, y: 38)
                            .blendMode(.destinationOut)
                            .overlay {
                                Image(systemName: "camera")
                                    .resizable()
                                    .scaledToFit()
                                    .font(.system(size: 12))
                                    .frame(width: 12, height: 12)
                                    .padding(6)
                                    .background(Color.App.textSecondary)
                                    .clipShape(RoundedRectangle(cornerRadius:(18)))
                                    .foregroundColor(.white)
                                    .fontWeight(.heavy)
                                    .offset(x: 68, y: 38)

                            }
                    }
                    .compositingGroup()
                    .opacity(0.9)
                }

                TextField("Setting.EditProfile.firstNameHint".bundleLocalized(), text: $viewModel.firstName)
                    .focused($focusedField, equals: .firstName)
                    .font(Font.normal(.body))
                    .submitLabel(.done)
                    .padding()
                    .frame(maxWidth: 420)
                    .disabled(viewModel.temporaryDisable)
                    .foregroundStyle(Color.App.textSecondary.opacity(0.6))
                    .applyAppTextfieldStyle(topPlaceholder: "Setting.EditProfile.firstName", isFocused: focusedField == .firstName) {
                        focusedField = .firstName
                    }
                TextField("Setting.EditProfile.lastNameHint".bundleLocalized(), text: $viewModel.lastName)
                    .focused($focusedField, equals: .lastName)
                    .font(Font.normal(.body))
                    .submitLabel(.done)
                    .padding()
                    .frame(maxWidth: 420)
                    .disabled(viewModel.temporaryDisable)
                    .foregroundStyle(Color.App.textSecondary.opacity(0.6))
                    .applyAppTextfieldStyle(topPlaceholder: "Setting.EditProfile.lastName" , isFocused: focusedField == .lastName) {
                        focusedField = .lastName
                    }

                TextField("Setting.EditProfile.userNameHint".bundleLocalized(), text: $viewModel.userName)
                    .focused($focusedField, equals: .userName)
                    .font(Font.normal(.body))
                    .submitLabel(.done)
                    .padding()
                    .frame(maxWidth: 420)
                    .disabled(viewModel.temporaryDisable)
                    .foregroundStyle(Color.App.textSecondary.opacity(0.6))
                    .applyAppTextfieldStyle(topPlaceholder: "Setting.EditProfile.userName", isFocused: focusedField == .userName) {
                        focusedField = .userName
                    }
                TextField("Setting.EditProfile.bioHint".bundleLocalized(), text: $viewModel.bio, axis: .vertical)
                    .focused($focusedField, equals: .bio)
                    .font(Font.normal(.body))
                    .padding()
                    .frame(maxWidth: 420)
//                    .disabled(viewModel.temporaryDisable)
                    .applyAppTextfieldStyle(topPlaceholder: "Setting.EditProfile.bio", minHeight: 128, isFocused: focusedField == .bio) {
                        focusedField = .bio
                    }
                    .toolbar {
                        ToolbarItem(placement: .keyboard) {
                            Button("", systemImage: "chevron.down") {
                                hideKeyboard()
                            }
                        }
                    }


                Text("Setting.EditProfile.bioHintMore")
                    .foregroundStyle(Color.App.textSecondary)
                    .font(Font.normal(.subheadline))
                    .padding(.horizontal)
                    .frame(maxWidth: 420, alignment: .leading)


                let address = "\(AppState.shared.spec.server.panel)\(AppState.shared.spec.paths.panel.info)"
                Link(destination: URL(string: address)!) {
                    HStack {
                        Text("Setting.EditProfile.enterToPodAccount")
                            .foregroundStyle(Color.App.textPrimary)
                            .font(Font.bold(.body))
                            .multilineTextAlignment(.center)
                    }
                    .buttonStyle(.plain)
                    .frame(height: 52)
                    .frame(minWidth: 0, maxWidth: 420)
                    .background(Color.App.bgSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .inset(by: 0.5)
                            .stroke(Color.App.textSecondary, lineWidth: 1)
                    )
                }
                .padding(.horizontal)
                Spacer()
            }
            .frame(minWidth: 0, maxWidth: .infinity)
        }
        .animation(.easeInOut, value: focusedField)
        .background(Color.App.bgPrimary.ignoresSafeArea())
        .font(Font.normal(.subheadline))
        .safeAreaInset(edge: .bottom) {
            SubmitBottomButton(text: "General.submit",
                               enableButton: .constant(true),
                               isLoading: $viewModel.isLoading,
                               maxInnerWidth: 420
            ) {
                viewModel.submit()
            }
            .disabled(viewModel.isLoading)
        }
        .onTapGesture {
            hideKeyboard()
        }
        .sheet(isPresented: $viewModel.showImagePicker) {
            ImagePicker(sourceType: .photoLibrary) { image, assestResources in
                Task { @MainActor in
                    viewModel.showImagePicker = false
                    self.viewModel.image = image
                    self.viewModel.assetResources = assestResources ?? []
                }
            }
        }
        .normalToolbarView(title: "Settings.EditProfile.title", type: String.self)
        .onReceive(viewModel.$dismiss) { newValue in
            if newValue {
                dismiss()
            }
        }
    }
}

extension PHAssetResource: @unchecked @retroactive Sendable {}

struct EditProfileView_Previews: PreviewProvider {
    static var previews: some View {
        EditProfileView()
    }
}
