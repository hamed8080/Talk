//
//  MemberView.swift
//  Talk
//
//  Created by hamed on 3/7/22.
//

import Chat
import SwiftUI
import TalkModels
import TalkUI
import TalkViewModels
import ActionableContextMenu

struct MemberView: View {
    @EnvironmentObject var viewModel: ParticipantsViewModel

    var body: some View {
        LazyVStack(spacing: 0) {
            ParticipantSearchView()
            AddParticipantButton(conversation: viewModel.thread)
                .listRowSeparatorTint(.gray.opacity(0.2))
                .listRowBackground(Color.App.bgPrimary)
            StickyHeaderSection(header: "", height: 10)

            if viewModel.searchedParticipants.count > 0 || !viewModel.searchText.isEmpty {
                StickyHeaderSection(header: "Memebers.searchedMembers")
                ForEach(viewModel.searchedParticipants) { participant in
                    ParticipantRowContainer(participant: participant, isSearchRow: true)
                }
            } else {
                ForEach(viewModel.sorted) { participant in
                    ParticipantRowContainer(participant: participant, isSearchRow: false)
                }
            }
        }
        .animation(.easeInOut, value: viewModel.participants.count)
        .animation(.easeInOut, value: viewModel.searchedParticipants.count)
        .animation(.easeInOut, value: viewModel.searchText)
        .animation(.easeInOut, value: viewModel.lazyList.isLoading)
        .ignoresSafeArea(.all)
        .padding(.bottom)
        .onAppear {
            if viewModel.participants.count == 0 {
                Task {
                    await viewModel.getParticipants()
                }
            }
        }
    }
}

struct ParticipantRowContainer: View {
    @State private var showPopover = false
    @EnvironmentObject var viewModel: ParticipantsViewModel
    let participant: Participant
    let isSearchRow: Bool
    var separatorColor: Color {
        if !isSearchRow {
            return viewModel.participants.last == participant ? Color.clear : Color.App.dividerPrimary
        } else {
            return viewModel.searchedParticipants.last == participant ? Color.clear : Color.App.dividerPrimary
        }
    }

    var body: some View {
        ParticipantRow(participant: participant)
            .id("\(isSearchRow ? "SearchRow" : "Normal")\(participant.id ?? 0)")
            .padding(.vertical)
            .background(Color.App.bgPrimary)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(separatorColor)
                    .frame(height: 0.5)
                    .padding(.leading, 64)
            }
            .onAppear {
                if viewModel.participants.last == participant {
                    Task {
                        await viewModel.loadMore()
                    }
                }
            }
            .onTapGesture {
                if !isMe {
                    AppState.shared.openThread(participant: participant)
                }
            }
            .onLongPressGesture {
                if !isMe, viewModel.thread?.admin == true {
                    showPopover.toggle()
                }
            }
            .popover(isPresented: $showPopover, attachmentAnchor: .point(.bottom), arrowEdge: .bottom) {
                VStack(alignment: .leading, spacing: 0) {
                    if !isMe, viewModel.thread?.admin == true, (participant.admin ?? false) == false {
                        ContextMenuButton(title: "Participant.addAdminAccess".bundleLocalized(), image: "person.crop.circle.badge.plus") {
                            viewModel.makeAdmin(participant)
                            showPopover.toggle()
                        }
                    }

                    if !isMe, viewModel.thread?.admin == true, (participant.admin ?? false) == true {
                        ContextMenuButton(title: "Participant.removeAdminAccess".bundleLocalized(), image: "person.crop.circle.badge.minus") {
                            viewModel.removeAdminRole(participant)
                            showPopover.toggle()
                        }
                    }

                    if !isMe, viewModel.thread?.admin == true {
                        ContextMenuButton(title: "General.delete".bundleLocalized(), image: "trash") {
                            let dialog = AnyView(
                                DeleteParticipantDialog(participant: participant)
                                    .environmentObject(viewModel)
                            )
                            AppState.shared.objectsContainer.appOverlayVM.dialogView = dialog
                            showPopover.toggle()
                        }
                        .foregroundStyle(Color.App.red)
                    }
                }
                .foregroundColor(.primary)
                .frame(width: 246)
                .background(MixMaterialBackground())
                .clipShape(RoundedRectangle(cornerRadius:((12))))
                .presentationCompactAdaptation(horizontal: .popover, vertical: .popover)
            }
    }

    private var isMe: Bool {
       participant.id == AppState.shared.user?.id
    }
}

struct AddParticipantButton: View {
    @State var presentSheet: Bool = false
    let conversation: Conversation?

    var body: some View {
        if conversation?.group == true, conversation?.admin == true{
            Button {
                presentSheet.toggle()
            } label: {
                HStack(spacing: 24) {
                    Image(systemName: "person.badge.plus")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 16)
                        .foregroundStyle(Color.App.accent)
                    Text("Thread.invite")
                        .font(.iransansBody)
                    Spacer()
                }
                .foregroundStyle(Color.App.accent)
                .padding(EdgeInsets(top: 16, leading: 24, bottom: 16, trailing: 24))
            }
            .sheet(isPresented: $presentSheet) {
                AddParticipantsToThreadView() { contacts in
                    addParticipantsToThread(contacts)
                    presentSheet.toggle()
                }
            }
        }
    }

    public func addParticipantsToThread(_ contacts: ContiguousArray<Contact>) {
        guard let threadId = conversation?.id else { return }
        let contactIds = contacts.compactMap(\.id)
        let req = AddParticipantRequest(contactIds: contactIds, threadId: threadId)
        Task { @ChatGlobalActor in
            ChatManager.activeInstance?.conversation.participant.add(req)
        }
    }
}

struct ParticipantSearchView: View {
    @EnvironmentObject var viewModel: ParticipantsViewModel
    @State private var showPopover = false

    var body: some View {
        HStack(spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(Color.App.textSecondary)
                    .frame(width: 16, height: 16)
                TextField("General.searchHere".bundleLocalized(), text: $viewModel.searchText)
                    .frame(minWidth: 0, minHeight: 48)
                    .font(.iransansBody)
            }
            Spacer()

            Button {
                showPopover.toggle()
            } label: {
                HStack {
                    Text(viewModel.searchType.rawValue)
                        .font(.iransansBoldCaption3)
                        .foregroundColor(Color.App.textSecondary)
                    Image(systemName: "chevron.down")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 8, height: 12)
                        .fontWeight(.medium)
                        .foregroundColor(Color.App.textSecondary)
                }
            }
            .popover(isPresented: $showPopover, arrowEdge: .bottom) {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(SearchParticipantType.allCases.filter({$0 != .admin })) { item in
                        Button {
                            withAnimation {
                                viewModel.searchType = item
                                showPopover.toggle()
                            }
                        } label: {
                            Text(item.rawValue)
                                .font(.iransansBoldCaption3)
                                .foregroundColor(Color.App.textSecondary)
                        }
                        .padding(8)
                    }
                }
                .padding(8)
                .presentationCompactAdaptation(.popover)
            }
        }
        .padding(EdgeInsets(top: 8, leading: 8, bottom: 0, trailing: 8))
        .background(Color.App.dividerSecondary)
        .animation(.easeInOut, value: viewModel.searchText)
    }
}

struct MemberView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = ParticipantsViewModel()
        List {
            MemberView()
        }
        .listStyle(.plain)
        .environmentObject(viewModel)
    }
}
