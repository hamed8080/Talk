//
//  EditGroup.swift
//  Talk
//
//  Created by hamed on 10/20/23.
//

import SwiftUI
import TalkUI
import TalkViewModels
import AdditiveUI
import TalkModels
import ChatModels

struct EditGroup: View {
    var threadVM: ThreadViewModel?
    @EnvironmentObject var viewModel: EditConversationViewModel
    @Environment(\.dismiss) var dismiss

    enum EditGroupFocusFields: Hashable {
        case name
        case description
    }
    
    @FocusState var focusState: EditGroupFocusFields?
    @State var showImagePicker: Bool = false
    
    var body: some View {
        List {
            threadImageView
            sectionSpacerView
            groupNameView
            descriptionView
            buttonRows
        }
        .environment(\.defaultMinListRowHeight, 8)
        .animation(.easeInOut, value: focusState)
        .padding(0)
        .listStyle(.plain)
        .background(Color.App.bgSecondary)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            SubmitBottomButton(text: "General.done", enableButton: Binding(get: {!viewModel.isLoading}, set: {_ in}), isLoading: $viewModel.isLoading) {
                viewModel.submitEditGroup()
            }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(sourceType: .photoLibrary) { image, assestResources in
                Task { @MainActor in
                    showImagePicker = false
                    self.viewModel.image = image
                    self.viewModel.assetResources = assestResources ?? []
                    self.viewModel.animateObjectWillChange()
                }
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            toolbarView
        }
        .onChange(of: viewModel.dismiss) { newValue in
            if newValue == true {
                /// Removing this line lead to after user clicks on the submit edit and then in edit thread we click again on the pencil button it will dismiss again.
                viewModel.dismiss = false
                dismiss()
            }
        }
        .onAppear {
            if viewModel.adminCounts == 0 {
                viewModel.getAdminsCount()
            }
        }
    }

    @ViewBuilder
    private var buttonRows: some View {
        let isChannel = viewModel.thread.type?.isChannelType == true
        let isPublic = viewModel.thread.type?.isPrivate == false
        let typeName = String(localized: .init(isChannel ? "Thread.channel" : "Thread.group"), bundle: Language.preferedBundle)
        let localizedPublic = String(localized: isPublic ? .init("Thread.public") : "Thread.private", bundle: Language.preferedBundle)
        let localizedDelete = String(localized: .init("Thread.delete"), bundle: Language.preferedBundle)
        let localizedMainString = String(localized: .init("Thread.typeString"), bundle: Language.preferedBundle)

        Group {
            StickyHeaderSection(header: "", height: 2)
                .listRowBackground(Color.App.bgPrimary)
                .listRowInsets(.zero)
                .noSeparators()

            if isChannel {
                item(title: String(format: localizedMainString, typeName, localizedPublic), image: "", assetImage: "ic_channel")
            } else {
                item(title: String(format: localizedMainString, typeName, localizedPublic), image: "person.2")
            }


            let adminsCount = viewModel.adminCounts.localNumber(locale: Language.preferredLocale) ?? ""
            item(title: String(localized: .init("EditGroup.admins"), bundle: Language.preferedBundle), image: "person.badge.shield.checkmark", rightLabelText: adminsCount)

            let participantsCount = threadVM?.thread.participantCount?.localNumber(locale: Language.preferredLocale) ?? ""
            item(title: String(localized: .init("Thread.Tabs.members"), bundle: Language.preferedBundle), image: "person.2", rightLabelText: participantsCount)

            toggleReactionsView
            if viewModel.isReactionsEnabled {
                CustomizeReactionsNavigationLink(threadVM: threadVM)
            }

            //                if EnvironmentValues.isTalkTest {
            //                    Toggle(isOn: $viewModel.isPublic) {
            //                        Text(String(format: localizedPublic, typeName))
            //                    }
            //                    .toggleStyle(MyToggleStyle())
            //                    .padding(.horizontal)
            //                    .listRowBackground(Color.App.bgSecondary)
            //                    .listRowSeparatorTint(Color.App.dividerPrimary)
            //                    .disabled(isPublic)
            //                    .opacity(isPublic ? 0.5 : 1.0)
            //                }

            StickyHeaderSection(header: "", height: 2)
                .listRowBackground(Color.App.bgPrimary)
                .listRowInsets(.zero)
                .noSeparators()

            item(title: String(format: localizedDelete, typeName), image: "trash", textColor: Color.App.red, iconColor: Color.App.red, showDivider: false) {
                AppState.shared.objectsContainer.appOverlayVM.dialogView = AnyView(DeleteThreadDialog(threadId: viewModel.thread.id))
            }

            Rectangle()
                .fill(Color.clear)
                .frame(height: 16)
                .listRowBackground(Color.clear)
                .listRowSeparatorTint(Color.clear)
        }
    }

    private var threadImageView: some View {
        HStack {
            Spacer()

            Button {
                showImagePicker = true
            } label: {
                ZStack(alignment: .leading) {
                    /// Showing the image that user has selected.
                    if let image = viewModel.image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 72, height: 72)
                            .clipShape(RoundedRectangle(cornerRadius:(32)))
                        if let percent = viewModel.uploadProfileProgress {
                            Circle()
                                .trim(from: 0.0, to: min(Double(percent) / 100, 1.0))
                                .stroke(style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                                .foregroundColor(Color.App.accent)
                                .rotationEffect(Angle(degrees: 270))
                                .frame(width: 73, height: 73)
                        }
                    } else {
                        ImageLoaderView(conversation: viewModel.thread)
                            .scaledToFit()
                            .id(viewModel.thread.id)
                            .font(.iransansBoldCaption2)
                            .foregroundColor(.white)
                            .frame(width: 72, height: 72)
                            .background(Color(uiColor: String.getMaterialColorByCharCode(str: viewModel.thread.computedTitle)))
                            .clipShape(RoundedRectangle(cornerRadius:(32)))
                    }
                    Circle()
                        .fill(.red)
                        .frame(width: 28, height: 28)
                        .offset(x: 42, y: 22)
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
                                .offset(x: 42, y: 22)

                        }
                }
                .compositingGroup()
                .opacity(0.9)
            }
            Spacer()
        }
        .padding()
        .listRowBackground(Color.App.bgSecondary)
        .noSeparators()
    }

    private var sectionSpacerView: some View {
        StickyHeaderSection(header: "", height: 2)
            .listRowBackground(Color.App.bgSecondary)
            .listRowInsets(.zero)
            .noSeparators()
    }

    private var groupNameView: some View {
        TextField("EditGroup.groupName".bundleLocalized(), text: $viewModel.editTitle)
            .focused($focusState, equals: .name)
            .keyboardType(.default)
            .submitLabel(.done)
            .padding()
            .applyAppTextfieldStyle(topPlaceholder: "EditGroup.groupName", innerBGColor: Color.App.bgSendInput, isFocused: focusState == .name) {
                focusState = .name
            }
            .noSeparators()
            .listRowBackground(Color.App.bgSecondary)
    }

    private var descriptionView: some View {
        TextField("EditGroup.groupDescription".bundleLocalized(), text: $viewModel.threadDescription)
            .focused($focusState, equals: .description)
            .keyboardType(.default)
            .padding()
            .applyAppTextfieldStyle(topPlaceholder: "EditGroup.groupDescription", innerBGColor: Color.App.bgSendInput, minHeight: 128, isFocused: focusState == .description) {
                focusState = .description
            }
            .noSeparators()
            .listRowBackground(Color.App.bgSecondary)
            .toolbar {
                ToolbarItem(placement: .keyboard) {
                    HStack {
                        Button("", systemImage: "chevron.down") {
                            hideKeyboard()
                        }
                        .fontWeight(.bold)
                        .offset(x: -4)
                        Spacer()
                    }
                }
            }
    }

    var toolbarView: some View {
        VStack(spacing: 0) {
            ToolbarView(title: "General.edit",
                        showSearchButton: false,
                        leadingViews: leadingTralingView,
                        centerViews: EmptyView(),
                        trailingViews: EmptyView()) {_ in }
        }
    }

    var leadingTralingView: some View {
        NavigationBackButton(automaticDismiss: true) {}
    }

    @ViewBuilder private func item(title: String,
                                   image: String,
                                   assetImage: String? = nil,
                                   rightLabelText: String = "",
                                   textColor: Color = Color.App.textPrimary,
                                   iconColor: Color = Color.App.textSecondary,
                                   showDivider: Bool = true,
                                   action: (() -> Void)? = nil) -> some View {
        Button {
            action?()
        } label: {
            HStack {
                if let assetImage = assetImage {
                    Image(assetImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                        .clipped()
                        .font(.iransansBody)
                        .foregroundStyle(iconColor)
                } else {
                    Image(systemName: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                        .clipped()
                        .font(.iransansBody)
                        .foregroundStyle(iconColor)
                }
                Text(title)
                    .foregroundStyle(textColor)
                Spacer()
                Text(rightLabelText)
                    .foregroundStyle(Color.App.accent)
                    .font(.iransansBoldBody)
            }
        }
        .buttonStyle(.borderless)
        .padding(.horizontal, 8)
        .listRowBackground(Color.App.bgSecondary)
        .listRowSeparatorTint(showDivider ? Color.App.dividerPrimary : Color.clear)
    }

    private func canShowCustomReactionToggle() -> Bool {
        return viewModel.thread.group == true && viewModel.thread.admin == true
    }

    @ViewBuilder
    private var toggleReactionsView: some View {
        if canShowCustomReactionToggle() {
            HStack {
                HStack {
                    Image(systemName: "face.smiling")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                        .clipped()
                        .font(.iransansBody)
                        .foregroundStyle(Color.App.textSecondary)

                    Text("EditGroup.enableReactions".bundleLocalized())
                }
                Spacer()
                Toggle("", isOn: $viewModel.isReactionsEnabled)
                    .tint(Color.App.accent)
                    .scaleEffect(x: 0.8, y: 0.8, anchor: .center)
                    .offset(x: 8)
                    .labelsHidden()
            }
            .padding(.init(top: 0, leading: 8, bottom: 0, trailing: 8))
            .listSectionSeparator(.hidden)
            .listRowBackground(Color.App.bgSecondary)
            .listRowSeparatorTint(Color.App.dividerPrimary)
        }
    }
}

// It should be on a different struct view due to a cpu usage of 100%.
struct CustomizeReactionsNavigationLink: View {
    let threadVM: ThreadViewModel?

    var body: some View {
        // Show custom reactions
        NavigationLink {
            if let viewModel = threadVM {
                CustomizeReactionsViewUIKitWrapper(viewModel: viewModel)
                    .ignoresSafeArea(.all)
                    .toolbar(.hidden, for: .navigationBar)
            } else {
                EmptyView()
            }
        } label: {
            HStack {
                Image(systemName: "face.smiling")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                    .clipped()
                    .font(.iransansBody)
                    .foregroundStyle(Color.App.textSecondary)

                Text("EditGroup.customizedReactions".bundleLocalized())
                Spacer()
            }
        }
        .padding(.init(top: 0, leading: 8, bottom: 0, trailing: 8))
        .listSectionSeparator(.hidden)
        .listRowBackground(Color.App.bgSecondary)
        .listRowSeparatorTint(Color.App.dividerPrimary)
    }
}

struct EditGroup_Previews: PreviewProvider {
    static var previews: some View {
        EditGroup(threadVM: .init(thread: .init()))
            .environmentObject(ThreadDetailViewModel())
    }
}
