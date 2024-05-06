//
//  ConversationBuilder.swift
//  Talk
//
//  Created by hamed on 10/19/23.
//

import SwiftUI
import TalkViewModels
import TalkUI
import PhotosUI
import ChatModels
import TalkModels

struct ConversationBuilder: View {
    @EnvironmentObject var viewModel: ConversationBuilderViewModel
    @State private var showNextPage = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                SelectedContactsView()
                    .padding(.horizontal, 8)
                    .background(Color.App.bgPrimary)
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
                    .onDelete(perform: viewModel.delete)
                    .padding()
                    .listRowInsets(.zero)
                }
                .listStyle(.plain)
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    TextField("General.searchHere".bundleLocalized(), text: $viewModel.searchContactString)
                        .frame(height: 48)
                        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                }
                .background(.ultraThinMaterial)
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                NavigationLink {
                    EditCreatedConversationDetail()
                        .navigationBarBackButtonHidden(true)
                } label: {
                    SubmitBottomLabel(text: "General.next",
                                       enableButton: .constant(enabeleButton),
                                       isLoading: $viewModel.isCreateLoading)
                }
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

    private var enabeleButton: Bool {
        viewModel.selectedContacts.count > 1 && !viewModel.lazyList.isLoading
    }
}

struct SelectedContactsView: View {
    @EnvironmentObject var viewModel: ConversationBuilderViewModel
    @State private var width: CGFloat = 200

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVGrid(columns: columns, alignment: .center) {
                ForEach(viewModel.selectedContacts) { contact in
                    SelectedContact(viewModel: viewModel, contact: contact)
                }
            }
        }
        .padding(.vertical, viewModel.selectedContacts.count == 0 ? 0 : 4 )
        .background(frameReader)
        .frame(height: height)
        .clipped()
    }

    private var frameReader: some View {
        GeometryReader { reader in
            Color.clear.onAppear {
                width = reader.size.width
                print("width offf:\(width)_")
            }
        }
    }

    private var height: CGFloat {
        if viewModel.selectedContacts.count == 0 { return 0 }
        let MAX: CGFloat = 126
        let rows: CGFloat = ceil(CGFloat(viewModel.selectedContacts.count) / CGFloat(2))
        if rows >= 4 { return MAX }
        return max(48, rows * 42)
    }

    private var columns: Array<GridItem> {
        let numberOfColumns = width / 2
        let flexible = GridItem.Size.flexible(minimum: numberOfColumns, maximum: numberOfColumns)
        let item = GridItem(flexible,spacing: 8)
        return Array(repeating: item, count: 2)
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
            let typeName = String(localized: .init(isChannel ? "Thread.channel" : "Thread.group"), bundle: Language.preferedBundle)
            let localizedPublic = String(localized: .init("Thread.public"), bundle: Language.preferedBundle)


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
                    ContactRow(isInSelectionMode: .constant(false))
                        .environmentObject(contact)
                        .listRowBackground(Color.App.bgPrimary)
                        .listRowSeparatorTint(Color.App.dividerPrimary)
                }
                .onDelete(perform: viewModel.delete)
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
            SubmitBottomButton(text: viewModel.createConversationType?.isGroupType == true ? "Contacts.createGroup" : "Contacts.createChannel",
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
                viewModel.image = image
                viewModel.assetResources = assestResources ?? []
                viewModel.animateObjectWillChange()
                showImagePicker = false
                viewModel.startUploadingImage()
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
            .font(.iransansBody)
            .padding()
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
                                    viewModel.cancelUploadImage()
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
            .id("\(isSearchRow ? "SearchRow" : "Normal")\(contact.id ?? 0)\(contact.blocked == true ? "Blocked" : "UnBlocked")")
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
                let config = ImageLoaderConfig(url: contact.image ?? contact.user?.image ?? "", userName: String.splitedCharacter(contact.firstName ?? ""))
                ImageLoaderView(imageLoader: .init(config: config))
                    .id("\(contact.image ?? "")\(contact.id ?? 0)")
                    .font(.iransansBody)
                    .foregroundColor(Color.App.textPrimary)
                    .frame(width: 52, height: 52)
                    .background(String.getMaterialColorByCharCode(str: contact.firstName ?? ""))
                    .clipShape(RoundedRectangle(cornerRadius:(22)))

                VStack(alignment: .leading, spacing: 2) {
                    Text(verbatim: "\(contact.firstName ?? "") \(contact.lastName ?? "")")
                        .padding(.leading, 16)
                        .lineLimit(1)
                        .font(.iransansBoldBody)
                        .foregroundColor(Color.App.textPrimary)
//                    if let notSeenDuration = contact.notSeenDuration?.localFormattedTime {
//                        let lastVisitedLabel = String(localized: .init("Contacts.lastVisited"), bundle: Language.preferedBundle)
//                        let time = String(format: lastVisitedLabel, notSeenDuration)
//                        Text(time)
//                            .padding(.leading, 16)
//                            .font(.iransansBody)
//                            .foregroundColor(Color.App.textSecondary)
//                    }
                }
                Spacer()
                if contact.blocked == true {
                    Text("General.blocked")
                        .font(.iransansCaption2)
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
