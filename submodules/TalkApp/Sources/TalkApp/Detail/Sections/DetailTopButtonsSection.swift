//
//  DetailTopButtonsSection.swift
//  Talk
//
//  Created by hamed on 5/6/24.
//

import SwiftUI
import TalkViewModels
import TalkUI
import Chat

@available(iOS 16.4, macOS 13.3, tvOS 16.4, watchOS 9.4, *)
struct DetailTopButtonsSection: View {
    @EnvironmentObject var viewModel: ThreadDetailViewModel
    @EnvironmentObject var contactViewModel: ContactsViewModel
    @State private var showPopover = false

    var body: some View {
        HStack(spacing: 16) {
            Spacer()
            let isArchive = viewModel.thread?.isArchive == true
            let isGroup = viewModel.thread?.group == true
            let isP2PContact = !isGroup
            
            if viewModel.thread?.type != .selfThread {
                if isGroup {
                    DetailViewButton(accessibilityText: "", icon: "", assetImageIconName: "ic_exit") {
                        onLeaveConversationTapped()
                    }
                } else if isP2PContact {
                    if deletableParticipantContact != nil {
                        DetailViewButton(accessibilityText: "", icon: "trash") {
                            onDeleteContactTapped()
                        }
                    } else {
                        DetailViewButton(accessibilityText: "", icon: "person.badge.plus") {
                            onAddContactTapped()
                        }
                    }
                }
                
                DetailViewButton(accessibilityText: "", icon: viewModel.thread?.mute ?? false ? "bell.slash.fill" : "bell.fill") {
                    viewModel.toggleMute()
                }
                .opacity(isArchive ? 0.4 : 1.0)
                .disabled(isArchive)
                .allowsHitTesting(!isArchive)

                DetailViewButton(accessibilityText: "", icon: "", assetImageIconName: "ic_export") {

                }
                .disabled(true)
                .opacity(0.4)
                .allowsHitTesting(false)
                
                DetailViewButton(accessibilityText: "", icon: "person") {

                }
                .disabled(true)
                .opacity(0.4)
                .allowsHitTesting(false)
            }
            //
            //            if viewModel.thread?.admin == true {
            //                DetailViewButton(accessibilityText: "", icon: viewModel.thread?.isPrivate == true ? "lock.fill" : "globe") {
            //                    viewModel.toggleThreadVisibility()
            //                }
            //            }

            //            Menu {
            //                if let conversation = viewModel.thread {
            //                    ThreadRowActionMenu(isDetailView: true, thread: conversation)
            //                        .environmentObject(AppState.shared.objectsContainer.threadsVM)
            //                }
            //                if let user = viewModel.user {
            //                    UserActionMenu(participant: user)
            //                }
            //            } label: {
            //                DetailViewButton(accessibilityText: "", icon: "ellipsis"){}
            //            }

            let thread = viewModel.thread
            let isEmptyThread = thread?.id == LocalId.emptyThread.rawValue
            let participant = viewModel.participantDetailViewModel?.participant
            
            DetailViewButton(accessibilityText: "", icon: "ellipsis") {
                showPopover.toggle()
            }
            .popover(isPresented: $showPopover, attachmentAnchor: .point(.bottom), arrowEdge: .top) {
                VStack(alignment: .leading, spacing: 0) {
                    if let thread = thread {
                        UserActionMenu(showPopover: $showPopover, participant: participant, thread: thread.toClass())
                            .environmentObject(AppState.shared.objectsContainer.threadsVM)
                    }
                }
                .environment(\.locale, Locale.current)
                .environment(\.layoutDirection, Language.isRTL ? .rightToLeft : .leftToRight)
                .font(Font.normal(.body))
                .foregroundColor(.primary)
                .frame(width: 246)
                .background(MixMaterialBackground())
                .clipShape(RoundedRectangle(cornerRadius:((12))))
                .presentationCompactAdaptation(horizontal: .popover, vertical: .sheet)
            }
            .disabled(isEmptyThread)
            .opacity(isEmptyThread ? 0.4 : 1.0)
            .allowsTightening(!isEmptyThread)
            Spacer()
        }
        .padding([.leading, .trailing])
        .buttonStyle(.plain)
        .disabled(viewModel.thread?.closed == true)
        .opacity(viewModel.thread?.closed == true ? 0.4 : 1.0)
    }
    
    private func onLeaveConversationTapped() {
        guard let thread = viewModel.thread else { return }
        showPopover = false
        AppState.shared.objectsContainer.appOverlayVM.dialogView = AnyView(LeaveThreadDialog(conversation: thread))
    }

    private func onDeleteContactTapped() {
        guard let participant = deletableParticipantContact else { return }
        showPopover = false
        AppState.shared.objectsContainer.appOverlayVM.dialogView = AnyView(
            ConversationDetailDeleteContactDialog(participant: participant)
        )
    }
    
    private var deletableParticipantContact: Participant? {
        viewModel.participantDetailViewModel?.participant ?? emptyThreadContantParticipant()
    }
    
    private func emptyThreadContantParticipant() -> Participant? {
        let firstParticipant = emptyThreadParticipant()
        let hasContactId = firstParticipant?.contactId != nil
        let emptyThreadParticipnat = hasContactId ? firstParticipant : nil
        return emptyThreadParticipnat
    }
    
    private func emptyThreadParticipant() -> Participant? {
        let isEmptyThread = viewModel.thread?.id == LocalId.emptyThread.rawValue
        return isEmptyThread ? viewModel.thread?.participants?.first : nil
    }
    
    private func onAddContactTapped() {
        guard let participant = emptyThreadParticipant() else { return }
        showPopover = false
        let contact = Contact(cellphoneNumber: participant.cellphoneNumber,
                              email: participant.email,
                              firstName: participant.firstName,
                              lastName: participant.lastName,
                              user: .init(username: participant.username))
        contactViewModel.addContact = contact
        contactViewModel.showAddOrEditContactSheet = true
        contactViewModel.animateObjectWillChange()
    }
}

fileprivate struct DetailViewButton: View {
    let accessibilityText: String
    let icon: String
    let assetImageIconName: String?
    let action: (() -> Void)?
    
    init(accessibilityText: String, icon: String, assetImageIconName: String? = nil, action: (() -> Void)?) {
        self.accessibilityText = accessibilityText
        self.icon = icon
        self.assetImageIconName = assetImageIconName
        self.action = action
    }

    var body: some View {
        Button {
            action?()
        } label: {
            imageView
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)
                .transition(.asymmetric(insertion: .scale.animation(.easeInOut(duration: 2)), removal: .scale.animation(.easeInOut(duration: 2))))
                .accessibilityHint(accessibilityText)
                .foregroundColor(Color.App.accent)
                .contentShape(Rectangle())
        }
        .frame(width: 48, height: 48)
        .background(.ultraThickMaterial)
        .clipShape(RoundedRectangle(cornerRadius:(8)))
    }
    
    @ViewBuilder
    private var imageView: SwiftUI.Image {
        if let assetName = assetImageIconName {
            return assetImageIcon(name: assetName)
        } else {
            return systemIcon
        }
    }
    
    private func assetImageIcon(name: String) -> SwiftUI.Image {
        Image(name)
    }
    
    private var systemIcon: SwiftUI.Image {
        Image(systemName: icon)
    }
}

@available(iOS 16.4, macOS 13.3, tvOS 16.4, watchOS 9.4, *)
struct DetailTopButtonsSection_Previews: PreviewProvider {
    static var previews: some View {
        DetailTopButtonsSection()
    }
}
