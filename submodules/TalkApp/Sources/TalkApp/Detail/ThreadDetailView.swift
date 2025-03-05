//
//  DetailView.swift
//  Talk
//
//  Created by Hamed Hosseini on 6/5/21.
//

import SwiftUI
import TalkViewModels
import TalkModels

struct ThreadDetailView: View {
    @EnvironmentObject var viewModel: ThreadDetailViewModel
    @Environment(\.dismiss) private var dismiss    

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical) {
                VStack(spacing: 0) {
                    DetailSectionContainer()
                        .id("DetailSectionContainer")
                    
                    if #available(iOS 16.4, macOS 13.3, tvOS 16.4, watchOS 9.4, *) {
                        DetailTabContainer()
                            .id("DetailTabContainer")
                    }
                }
            }
            .onAppear {
                viewModel.scrollViewProxy = proxy
            }
        }
        .navigationBarBackButtonHidden(true)
        .background(Color.App.bgPrimary)
        .environmentObject(viewModel)
        .safeAreaInset(edge: .top, spacing: 0) { DetailToolbarContainer() }
        .background(DetailAddOrEditContactSheetView())
        .onReceive(viewModel.$dismiss) { newValue in
            if newValue {
                prepareToDismiss()
            }
        }
        .onAppear {
//            setupPreviousDetailViewModel()
        }
        .onDisappear {
            Task(priority: .background) {
                viewModel.threadVM?.searchedMessagesViewModel.reset()
            }
        }
    }

    private func prepareToDismiss() {
        AppState.shared.objectsContainer.navVM.remove(innerBack: false)
        AppState.shared.objectsContainer.threadDetailVM.clear()
        AppState.shared.appStateNavigationModel.userToCreateThread = nil
        dismiss()
    }

    var leadingViews: some View {
        NavigationBackButton(automaticDismiss: false) {
//            viewModel.threadVM?.scrollVM.disableExcessiveLoading()
//            AppState.shared.objectsContainer.contactsVM.editContact = nil
//            AppState.shared.objectsContainer.navVM.remove(type: ThreadDetailViewModel.self)
//            AppState.shared.objectsContainer.threadDetailVM.clear()
        }
    }
}


struct TarilingEditConversation: View {
    @EnvironmentObject var viewModel: ThreadDetailViewModel
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        if viewModel.canShowEditConversationButton == true {
            NavigationLink {
                if viewModel.canShowEditConversationButton, let viewModel = viewModel.editConversationViewModel {
                    EditGroup(threadVM: viewModel.threadVM)
                        .environmentObject(viewModel)
                        .navigationBarBackButtonHidden(true)
                }
            } label: {
                Image(systemName: "pencil")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                    .padding(8)
                    .foregroundStyle(colorScheme == .dark ? Color.App.accent : Color.App.white)
                    .fontWeight(.heavy)
            }
        } else if let viewModel = viewModel.participantDetailViewModel {
            EditContactTrailingButton()
                .environmentObject(viewModel)
        }
    }
}

struct EditContactTrailingButton: View {
    @EnvironmentObject var viewModel: ParticipantDetailViewModel
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        if viewModel.partnerContact != nil {
            NavigationLink {
                EditContactInParticipantDetailView()
                    .environmentObject(viewModel)
                    .background(Color.App.bgSecondary)
                    .navigationBarBackButtonHidden(true)
            } label: {
                Image(systemName: "pencil")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                    .padding(8)
                    .foregroundStyle(colorScheme == .dark ?  Color.App.accent : Color.App.white)
                    .fontWeight(.heavy)
            }
        }
    }
}

struct ThreadDescription: View {
    @EnvironmentObject var viewModel: ThreadDetailViewModel

    var body: some View {
        if let description = viewModel.thread?.description.validateString {
            InfoRowItem(key: "General.description", value: description, lineLimit: nil)
        }
    }
}

struct PublicLink: View {
    @EnvironmentObject var viewModel: ThreadDetailViewModel
    private var shortJoinLink: String { "talk/\(viewModel.thread?.uniqueName ?? "")" }
    private var joinLink: String {
        let talk = AppState.shared.spec.server.talk
        let talkJoin = "\(talk)\(AppState.shared.spec.paths.talk.join)"
        return "\(talkJoin)\(viewModel.thread?.uniqueName ?? "")"
    }

    var body: some View {
        if viewModel.thread?.uniqueName != nil {
            Button {
                UIPasteboard.general.string = joinLink
                let icon = Image(systemName: "doc.on.doc")
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.App.textPrimary)
                AppState.shared.objectsContainer.appOverlayVM.toast(leadingView: icon, message: "General.copied", messageColor: Color.App.textPrimary)
            } label: {
                InfoRowItem(key: "Thread.inviteLink", value: shortJoinLink, lineLimit: 1, button: AnyView(EmptyView()))
            }
        }
    }

    //    var qrButton: some View {
    //        Button {
    //            withAnimation {
    //                UIPasteboard.general.string = joinLink
    //            }
    //        } label: {
    //            Image(systemName: "qrcode")
    //                .resizable()
    //                .scaledToFit()
    //                .frame(width: 20, height: 20)
    //                .padding()
    //                .foregroundColor(Color.App.white)
    //                .contentShape(Rectangle())
    //        }
    //        .frame(width: 40, height: 40)
    //        .background(Color.App.textSecondary)
    //        .clipShape(RoundedRectangle(cornerRadius:(20)))
    //    }
}

struct InfoRowItem: View {
    let key: String
    let value: String
    let button: AnyView?
    let lineLimit: Int?

    init(key: String, value: String, lineLimit: Int? = 2, button: AnyView? = nil) {
        self.key = key
        self.value = value
        self.button = button
        self.lineLimit = lineLimit
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(key.bundleLocalized())
                    .font(.fCaption)
                    .foregroundStyle(Color.App.textSecondary)
                Text(value)
                    .font(.fSubtitle)
                    .foregroundStyle(Color.App.textPrimary)
                    .lineLimit(lineLimit)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)
            }
            Spacer()
            button
        }
        .padding()
    }
}

struct SectionItem: View {
    let title: String
    let systemName: String
    var action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            Label(title.bundleLocalized(), systemImage: systemName)
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 36, alignment: .leading)
        }
        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
        .padding([.top, .bottom], 2)
        .buttonStyle(.bordered)
        .clipShape(RoundedRectangle(cornerRadius:(12)))
    }
}

struct UserName: View {
    @EnvironmentObject var viewModel: ParticipantDetailViewModel

    var body: some View {
        if let participantName = viewModel.participant.username.validateString {
            InfoRowItem(key: "Settings.userName", value: participantName)
        }
    }
}

struct CellPhoneNumber: View {
    @EnvironmentObject var viewModel: ParticipantDetailViewModel

    var body: some View {
        if let cellPhoneNumber = viewModel.cellPhoneNumber.validateString {
            InfoRowItem(key: "Participant.Search.Type.cellphoneNumber", value: cellPhoneNumber)
        }
    }
}

struct DetailView_Previews: PreviewProvider {
    static var previews: some View {
        ThreadDetailView()
            .environmentObject(ThreadDetailViewModel())
    }
}
