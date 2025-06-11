//
//  ThreadRow.swift
//  Talk
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Chat
import SwiftUI
import TalkUI
import TalkViewModels
import TalkModels
import ActionableContextMenu
import TalkExtensions

struct ThreadRow: View {
    var isSearchRow: Bool = false
    @EnvironmentObject var thread: CalculatedConversation
    let onTap: (() -> Void)?
    
    var body: some View {
        HStack(spacing: 12) {
            SelectedThreadBar(isSelected: thread.isSelected)
            ThreadImageView()
                .id(thread.computedImageURL)
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    ThreadRowIcons(isSearchRow: isSearchRow)
                    Spacer()
                    
                    MutableMessageStatusView(isSelected: thread.isSelected)
                    ThreadTimeText(isSelected: thread.isSelected)
                }
                ThreadRowBottomContainer(isSelected: thread.isSelected)
            }
            .contentShape(Rectangle())
        }
        .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 8))
        .animation(.easeInOut, value: thread)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            if thread.group == true && (thread.admin == false || thread.admin == nil) {
                EmptyView()
            } else {
                Button {
                    AppState.shared.objectsContainer.appOverlayVM.dialogView = AnyView(DeleteThreadDialog(threadId: thread.id))
                } label: {
                    Label("General.delete", systemImage: "trash")
                }
                .tint(.red)
            }
        }
        .onTapGesture {
            onTap?()
        }
        .onLongPressGesture(minimumDuration: 0.5) {
            withAnimation {
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                AppState.shared.objectsContainer.appOverlayVM.clearBckground = true
                AppState.shared.objectsContainer.appOverlayVM.dialogView = AnyView(contextenuView)
            }
        }
    }
    
    private var contextenuView: some View {
        VStack(spacing: 8) {
            ThreadRow(onTap: nil)
                .padding(4)
                .environmentObject(thread)
                .background(ThreadListRowBackground().environmentObject(thread))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .frame(height: 52)
            ThreadRowContextMenu(thread: thread, viewModel: AppState.shared.objectsContainer.threadsVM)
                .simultaneousGesture(
                    TapGesture().onEnded {
                        AppState.shared.objectsContainer.appOverlayVM.dialogView = nil
                    }
                )
        }
        .padding()
    }
}

struct ThreadRowIcons: View {
    let isSearchRow: Bool
    @EnvironmentObject var thread: CalculatedConversation
    
    var body: some View {
        if thread.type?.isChannelType == true {
            Image("ic_channel")
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)
                .foregroundColor(thread.isSelected ? Color.App.textPrimary : Color.App.iconSecondary)
        }

        if thread.group == true, thread.type?.isChannelType == false {
            Image(systemName: "person.2.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)
                .foregroundColor(thread.isSelected ? Color.App.textPrimary : Color.App.iconSecondary)
        }
        if isSearchRow {
            Text(AppState.shared.objectsContainer.searchVM.attributdTitle(for: thread.titleRTLString ?? ""))
                .lineLimit(1)
                .font(.fSubheadline)
                .fontWeight(.semibold)
        } else {
            let title = thread.titleRTLString ?? ""
            Text(title)
                .lineLimit(1)
                .font(.fSubheadline)
                .fontWeight(.semibold)
                .animation(.easeInOut, value: title)
        }

        if thread.isTalk {
            Image("ic_approved")
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)
                .offset(x: -4)
        }
    }
}

struct ThreadRowBottomContainer: View {
    @EnvironmentObject var thread: CalculatedConversation
    let isSelected: Bool

    var body: some View {
        HStack {
            SecondaryMessageView(isSelected: isSelected)
                .environmentObject(thread.eventVM as? ThreadEventViewModel ?? .init(threadId: thread.id ?? -1))
            Spacer()
            if !thread.isInForwardMode {
                ThreadClosed()
                ThreadMentionSign()
                ThreadUnreadCount(isSelected: isSelected)
            }
        }
    }
}

struct ThreadRowSelfContextMenu: View {
    let thread: CalculatedConversation
    @Environment(\.layoutDirection) var direction
    @EnvironmentObject var ctxVM: ContextMenuModel

    var body: some View {
        ThreadRow(onTap: nil)
            .frame(height: 72)
            .frame(maxWidth: min(400, ctxVM.containerSize.width - 18)) /// 400 for ipad side bar
            .background(Color.App.bgSecondary)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .environmentObject(thread)
            .environmentObject(AppState.shared.objectsContainer.navVM)
            .environment(\.layoutDirection, direction == .leftToRight && Language.isRTL ? .rightToLeft : .leftToRight)
    }
}

struct ThreadRowContextMenu: View {
    let thread: CalculatedConversation
    let viewModel: ThreadsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ThreadRowActionMenu(showPopover: .constant(true), thread: thread)
                .environmentObject(viewModel)
        }
        .foregroundColor(.primary)
        .frame(width: 246)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius:((12))))
    }
}

struct ThreadMentionSign: View {
    @EnvironmentObject var thread: CalculatedConversation

    var body: some View {
        if thread.mentioned == true {
            Text("@")
                .font(.fCaption)
                .padding(6)
                .frame(height: 24)
                .frame(minWidth: 24)
                .foregroundStyle(Color.App.textPrimary)
                .background(Color.App.accent)
                .clipShape(RoundedRectangle(cornerRadius:(12)))
        }
    }
}

struct ThreadClosed: View {
    @EnvironmentObject var thread: CalculatedConversation

    var body: some View {
        if thread.closed == true {
            Image("lock")
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
                .foregroundStyle(Color.App.textSecondary)
        }
    }
}

struct SelectedThreadBar: View {
    let isSelected: Bool

    var body: some View {
        let isIpad = UIDevice.current.userInterfaceIdiom == .pad
        Rectangle()
            .fill(isSelected && isIpad ? Color.App.accent : .clear)
            .frame(width: 4)
            .frame(minHeight: 0, maxHeight: .infinity)
            .animation(.easeInOut, value: isSelected && isIpad)
    }
}

struct ThreadUnreadCount: View {
    @EnvironmentObject var thread: CalculatedConversation
    let isSelected: Bool

    var body: some View {
        ZStack {
            if !thread.unreadCountString.isEmpty {
                Text(thread.unreadCountString)
                    .font(.fBoldCaption2)
                    .padding(thread.isCircleUnreadCount ? 4 : 6)
                    .frame(height: 24)
                    .frame(minWidth: 24)
                    .foregroundStyle(thread.mute == true ? Color.App.white : isSelected ? Color.App.textSecondary : Color.App.textPrimary)
                    .background(thread.mute == true ? Color.App.iconSecondary : isSelected ? Color.App.white : Color.App.accent)
                    .clipShape(RoundedRectangle(cornerRadius:(thread.isCircleUnreadCount ? 16 : 10)))
            }
        }
        .animation(.easeInOut, value: thread.unreadCountString)
    }
}

struct ThreadTimeText: View {
    @EnvironmentObject var thread: CalculatedConversation
    let isSelected: Bool

    var body: some View {
        ZStack {
            if !thread.timeString.isEmpty {
                Text(thread.timeString)
                    .lineLimit(1)
                    .font(.fCaption2)
                    .fontWeight(.medium)
                    .foregroundColor(thread.isSelected ? Color.App.textPrimary : Color.App.iconSecondary)
            }
        }
        .animation(.easeInOut, value: thread.timeString)
        .animation(.easeInOut, value: thread.isSelected)
    }
}

#if DEBUG
struct ThreadRow_Previews: PreviewProvider {
    static var thread: Conversation {
        var thread = MockData.thread
        thread.title = "Hamed  Hosseini"
        thread.time = 1_675_186_636_000
        thread.pin = true
        thread.mute = true
        thread.mentioned = true
        thread.unreadCount = 20
        return thread
    }

    static var previews: some View {
        ThreadRow() {

        }
        .environmentObject(thread.toClass())
        .environmentObject(ThreadsViewModel())
    }
}
#endif
