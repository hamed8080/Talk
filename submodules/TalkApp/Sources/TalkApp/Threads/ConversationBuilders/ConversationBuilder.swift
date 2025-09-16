//
//  ConversationBuilder.swift
//  Talk
//
//  Created by hamed on 10/19/23.
//

import SwiftUI
import TalkViewModels
import TalkUI
import TalkModels
import Chat

struct ConversationBuilder: View {
    @EnvironmentObject var viewModel: ConversationBuilderViewModel
    @State private var showNextPage = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                SelectedContactsView()
                    .padding(.horizontal, 8)
                    .background(Color.App.bgPrimary)
                ScrollViewReader { proxy in
                    List {
                        if viewModel.searchedContacts.count > 0 {
                            StickyHeaderSection(header: "Contacts.searched")
                                .listRowInsets(.zero)
                                .listRowSeparator(.hidden)
                            ForEach(viewModel.searchedContacts) { contact in
                                BuilderContactRowContainer(contact: contact, isSearchRow: true)
                            }
                            .padding()
                            .listRowInsets(.zero)
                        } else if viewModel.searchContactString.count > 0, viewModel.searchedContacts.isEmpty {
                            if viewModel.isTypinginSearchString {
                                ListLoadingView(isLoading: .constant(true))
                            } else if !viewModel.lazyList.isLoading {
                                Text("General.noResult")
                                    .fontWeight(.medium)
                                    .foregroundStyle(Color.App.textSecondary)
                                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .center)
                                    .multilineTextAlignment(.center)
                                    .listRowBackground(Color.App.bgPrimary)
                                    .listRowSeparator(.hidden)
                                    .id("General.noResult")
                            }
                        }

                        StickyHeaderSection(header: "Contacts.selectContacts")
                            .listRowInsets(.zero)
                            .listRowSeparator(.hidden)
                        ForEach(viewModel.contacts) { contact in
                            BuilderContactRowContainer(contact: contact, isSearchRow: false)
                                .onAppear {
                                    Task {
                                        if viewModel.contacts.last == contact {
                                            await viewModel.loadMore()
                                        }
                                    }
                                }
                        }
                        .padding()
                        .listRowInsets(.zero)
                    }
                    .listStyle(.plain)
                    .onAppear {
                        viewModel.builderScrollProxy = proxy
                    }
                }
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    TextField("General.searchHere".bundleLocalized(), text: $viewModel.searchContactString)
                        .frame(height: 48)
                        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .submitLabel(.done)
                }
                .background(.ultraThinMaterial)
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                NavigationLink {
                    EditCreatedConversationDetail()
                        .navigationBarBackButtonHidden(true)
                } label: {
                    SubmitBottomLabel(text: "General.next",
                                       enableButton: .constant(enableButton),
                                       isLoading: $viewModel.isCreateLoading)
                }
                .disabled(!enableButton)
            }
        }
        .environment(\.defaultMinListRowHeight, 24)
        .animation(.easeInOut, value: viewModel.contacts)
        .animation(.easeInOut, value: viewModel.searchedContacts)
        .animation(.easeInOut, value: viewModel.isCreateLoading)
        .overlay(alignment: .bottom) {
            ListLoadingView(isLoading: $viewModel.isCreateLoading)
                .id(UUID())
        }
        .onAppear {
            /// We use BuilderContactRowContainer view because it is essential to force the ineer contactRow View to show radio buttons.
            viewModel.isInSelectionMode = true
        }
        .onDisappear {
            viewModel.isInSelectionMode = false
        }
    }

    private var enableButton: Bool {
        viewModel.selectedContacts.count > 1 && !viewModel.lazyList.isLoading
    }
}

struct SelectedContactsView: View {
    @EnvironmentObject var viewModel: ConversationBuilderViewModel
    @State private var width: CGFloat = 200

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            FlowLayout(spacing: 8) {
                ForEach(viewModel.selectedContacts) { contact in
                    SelectedContact(viewModel: viewModel, contact: contact)
                }
            }
        }
        .padding(.vertical, viewModel.selectedContacts.count == 0 ? 0 : 4 )
        .frame(height: height)
        .clipped()
    }

    private var height: CGFloat {
        if viewModel.selectedContacts.count == 0 { return 0 }
        let MAX: CGFloat = 126
        let rows: CGFloat = ceil(CGFloat(viewModel.selectedContacts.count) / CGFloat(2.0))
        if rows >= 4 { return MAX }
        return max(48, rows * 42)
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    var alignment: HorizontalAlignment = .leading

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        var width: CGFloat = 0
        var height: CGFloat = 0
        var rowHeight: CGFloat = 0

        let maxWidth = proposal.width ?? .infinity

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if width + size.width + spacing > maxWidth {
                width = 0
                height += rowHeight + spacing
                rowHeight = 0
            }

            rowHeight = max(rowHeight, size.height)
            width += size.width + spacing
        }

        return CGSize(width: maxWidth, height: height + rowHeight)
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        var x: CGFloat = bounds.minX
        var y: CGFloat = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if x + size.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }

            subview.place(
                at: CGPoint(x: x, y: y),
                anchor: .topLeading,
                proposal: ProposedViewSize(size)
            )

            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

/// Step two to edit title and picture of the group/channel....
struct EditCreatedConversationDetail: View {
    @EnvironmentObject var viewModel: ConversationBuilderViewModel
    @State var showImagePicker = false
    @FocusState private var focused: FocusFields?

    private enum FocusFields: Hashable {
        case title
    }

    var body: some View {
        List {
            HStack {
                imagePickerButton
                titleTextField
            }
            .frame(height: 88)
            .listRowBackground(Color.App.bgPrimary)
            .listRowSeparator(.hidden)

            StickyHeaderSection(header: "", height: 10)
                .listRowInsets(.zero)
                .listRowSeparator(.hidden)

            let type = viewModel.createConversationType
            let isChannel = type?.isChannelType == true
            let typeName = (isChannel ? "Thread.channel" : "Thread.group").bundleLocalized()
            let localizedPublic = "Thread.public".bundleLocalized()


            HStack(spacing: 8) {
                Text(String(format: localizedPublic, typeName))
                    .foregroundColor(Color.App.textPrimary)
                    .lineLimit(1)
                    .layoutPriority(1)
                Spacer()
                Toggle("", isOn: $viewModel.isPublic)
                    .tint(Color.App.accent)
                    .scaleEffect(x: 0.8, y: 0.8, anchor: .center)
                    .offset(x: 8)
            }
            .padding(.leading)
            .listRowBackground(Color.App.bgPrimary)
            .listRowSeparator(.hidden)

            Section {
                ForEach(viewModel.selectedContacts) { contact in
                    ContactRow(contact: contact, isInSelectionMode: .constant(false), isInSearchMode: true)
                        .listRowBackground(Color.App.bgPrimary)
                        .listRowSeparatorTint(Color.App.dividerPrimary)
                }
                .padding()
            } header: {
                StickyHeaderSection(header: "Thread.Tabs.members")
            }
            .listRowInsets(.zero)
        }
        .environment(\.defaultMinListRowHeight, 8)
        .background(Color.App.bgPrimary)
        .animation(.easeInOut, value: viewModel.contacts)
        .animation(.easeInOut, value: isLoading)
        .animation(.easeInOut, value: viewModel.conversationTitle)
        .listStyle(.plain)
        .safeAreaInset(edge: .top, spacing: 0) {
            NormalNavigationBackButton()
                .foregroundStyle(Color.App.accent)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            SubmitBottomButton(text: viewModel.createConversationType?.isGroupType == true ? "Contacts.createGroup".bundleLocalized() : "Contacts.createChannel".bundleLocalized(),
                               enableButton: .constant(!isLoading),
                               isLoading: .constant(isLoading))
            {
                viewModel.createGroup()
            }
        }
        .overlay(alignment: .bottom) {
            ListLoadingView(isLoading: $viewModel.lazyList.isLoading)
                .id(UUID())
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(sourceType: .photoLibrary) { image, assestResources in
                Task { @MainActor in
                    viewModel.image = image
                    viewModel.assetResources = assestResources ?? []
                    viewModel.animateObjectWillChange()
                    showImagePicker = false
//                    viewModel.startUploadingImage()
                }
            }
        }
    }

    private var isLoading: Bool {
        viewModel.isCreateLoading || viewModel.isUploading
    }

    var imagePickerButton: some View {
        Button {
            if !viewModel.isUploading {
                showImagePicker.toggle()
            }
        } label: {
            imagePickerButtonView
        }
        .buttonStyle(.borderless)
    }

    @ViewBuilder
    private var titleTextField: some View {
        let key = viewModel.createConversationType?.isGroupType == true ? "ConversationBuilder.enterGroupName" : "ConversationBuilder.enterChannelName"
        let error = viewModel.showTitleError ? "ConversationBuilder.atLeatsEnterTwoCharacter" : nil
        TextField(key.bundleLocalized(), text: $viewModel.conversationTitle)
            .focused($focused, equals: .title)
            .font(.fBody)
            .padding()
            .submitLabel(.done)
            .applyAppTextfieldStyle(topPlaceholder: "", error: error, isFocused: focused == .title) {
                focused = .title
            }
    }

    private var imagePickerButtonView: some View {
        ZStack {
            Rectangle()
                .fill(Color("bg_icon"))
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius:(28)))
                .overlay(alignment: .center) {
                    Image(systemName: "camera.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                        .foregroundStyle(Color.App.textSecondary)
                }

            /// Showing the image taht user has selected.
            if let image = viewModel.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 64, height: 64)
                    .clipShape(RoundedRectangle(cornerRadius:(28)))
                    .blur(radius: viewModel.isUploading ? 1.5 : 0.0)
                    .overlay(alignment: .center) {
                        if viewModel.isUploading {
                            Image(systemName: "xmark.circle.fill")
                                .frame(width: 24, height: 24)
                                .foregroundStyle(Color.App.textSecondary)
                                .onTapGesture {
//                                    viewModel.cancelUploadImage()
                                }
                        }
                        if let percent = viewModel.uploadProfileProgress {
                            RoundedRectangle(cornerRadius: 28)
                                .trim(from: 0.0, to: min(Double(percent) / 100, 1.0))
                                .stroke(style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                                .foregroundColor(Color.App.accent)
                                .rotationEffect(Angle(degrees: 270))
                                .frame(width: 61, height: 61)
                        }
                    }
            }
        }
        .frame(width: 64, height: 64)
        .background(Color.App.bgSecondary)
        .clipShape(RoundedRectangle(cornerRadius:(24)))
    }
}

struct BuilderContactRowContainer: View {
    @EnvironmentObject var viewModel: ConversationBuilderViewModel
    let contact: Contact
    let isSearchRow: Bool
    var separatorColor: Color {
        if !isSearchRow {
            return viewModel.contacts.last == contact ? Color.clear : Color.App.dividerPrimary
        } else {
            return viewModel.searchedContacts.last == contact ? Color.clear : Color.App.dividerPrimary
        }
    }

    var body: some View {
        ‌BuilderContactRow(isInSelectionMode: $viewModel.isInSelectionMode, contact: contact)
            .id("\(isSearchRow ? "SearchRow-" : "Normal-")\(contact.id ?? 0)")
            .animation(.spring(), value: viewModel.isInSelectionMode)
            .listRowBackground(Color.App.bgPrimary)
            .listRowSeparatorTint(separatorColor)
            .onAppear {
                Task {
                    if viewModel.contacts.last == contact {
                        await viewModel.loadMore()
                    }
                }
            }
            .onTapGesture {
                Task {
                    if viewModel.isInSelectionMode {
                        viewModel.toggleSelectedContact(contact: contact)
                    } else {
                        await viewModel.clear()
                        AppState.shared.openThread(contact: contact)
                    }
                }
            }
    }
}

struct ‌BuilderContactRow: View {
    @Binding public var isInSelectionMode: Bool
    let contact: Contact
    var contactImageURL: String? { contact.image ?? contact.user?.image }

    var body: some View {
        VStack {
            HStack(spacing: 0) {
                BuilderContactRowRadioButton(contact: contact)
                    .padding(.trailing, isInSelectionMode ? 8 : 0)
                ImageLoaderView(contact: contact)
                    .id("\(contact.image ?? "")\(contact.id ?? 0)")
                    .font(.fBody)
                    .foregroundColor(Color.App.textPrimary)
                    .frame(width: 52, height: 52)
                    .background(Color(uiColor: String.getMaterialColorByCharCode(str: contact.firstName ?? "")))
                    .clipShape(RoundedRectangle(cornerRadius:(22)))

                VStack(alignment: .leading, spacing: 2) {
                    Text(verbatim: "\(contact.firstName ?? "") \(contact.lastName ?? "")")
                        .padding(.leading, 16)
                        .lineLimit(1)
                        .font(.fBoldBody)
                        .foregroundColor(Color.App.textPrimary)
//                    if let notSeenDuration = contact.notSeenDuration?.localFormattedTime {
//                        let lastVisitedLabel = "Contacts.lastVisited".bundleLocalized()
//                        let time = String(format: lastVisitedLabel, notSeenDuration)
//                        Text(time)
//                            .padding(.leading, 16)
//                            .font(.fBody)
//                            .foregroundColor(Color.App.textSecondary)
//                    }
                }
                Spacer()
                if contact.blocked == true {
                    Text("General.blocked")
                        .font(.fCaption2)
                        .foregroundColor(Color.App.red)
                        .padding(.trailing, 4)
                }
            }
        }
        .contentShape(Rectangle())
        .animation(.easeInOut, value: contact.blocked)
        .animation(.easeInOut, value: contact)
    }

    var isOnline: Bool {
        contact.notSeenDuration ?? 16000 < 15000
    }
}


struct BuilderContactRowRadioButton: View {
    let contact: Contact
    @EnvironmentObject var viewModel: ConversationBuilderViewModel

    var body: some View {
        let isSelected = viewModel.isSelected(contact: contact)
        RadioButton(visible: $viewModel.isInSelectionMode, isSelected: .constant(isSelected)) { isSelected in
            viewModel.toggleSelectedContact(contact: contact)
        }
    }
}

struct CreateGroup_Previews: PreviewProvider {
    static var previews: some View {
        ConversationBuilder()
            .environmentObject(ContactsViewModel())
            .previewDisplayName("CreateConversation")
        EditCreatedConversationDetail()
            .environmentObject(ContactsViewModel())
            .previewDisplayName("EditCreatedConversationDetail")
    }
}
