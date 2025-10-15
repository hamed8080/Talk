//
//  DetailTopButtonsSection.swift
//  Talk
//
//  Created by hamed on 5/6/24.
//

import SwiftUI
import TalkViewModels
import TalkUI

@available(iOS 16.4, macOS 13.3, tvOS 16.4, watchOS 9.4, *)
struct DetailTopButtonsSection: View {
    @EnvironmentObject var viewModel: ThreadDetailViewModel
    @State private var showPopover = false

    var body: some View {
        HStack(spacing: 16) {
            Spacer()
            let isArchive = viewModel.thread?.isArchive == true
            if viewModel.thread?.type != .selfThread {
                DetailViewButton(accessibilityText: "", icon: viewModel.thread?.mute ?? false ? "bell.slash.fill" : "bell.fill") {
                    viewModel.toggleMute()
                }
                .opacity(isArchive ? 0.4 : 1.0)
                .disabled(isArchive)
                .allowsHitTesting(!isArchive)

                DetailViewButton(accessibilityText: "", icon: "phone.and.waveform.fill") {

                }
                .disabled(true)
                .opacity(0.4)
                .allowsHitTesting(false)

                DetailViewButton(accessibilityText: "", icon: "video.fill") {

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

            DetailViewButton(accessibilityText: "", icon: "ellipsis") {
                showPopover.toggle()
            }
            .popover(isPresented: $showPopover, attachmentAnchor: .point(.bottom), arrowEdge: .top) {
                VStack(alignment: .leading, spacing: 0) {
                    if let thread = viewModel.thread {
                        ThreadRowActionMenu(showPopover: $showPopover, isDetailView: true, thread: thread.toClass())
                            .environmentObject(AppState.shared.objectsContainer.threadsVM)
                    }
                    if let participant = viewModel.participantDetailViewModel?.participant {
                        UserActionMenu(showPopover: $showPopover, participant: participant)
                    }
                }
                .environment(\.locale, Locale.current)
                .environment(\.layoutDirection, Language.isRTL ? .rightToLeft : .leftToRight)
                .font(Font.fBody)
                .foregroundColor(.primary)
                .frame(width: 246)
                .background(MixMaterialBackground())
                .clipShape(RoundedRectangle(cornerRadius:((12))))
                .presentationCompactAdaptation(horizontal: .popover, vertical: .sheet)
            }
            Spacer()
        }
        .padding([.leading, .trailing])
        .buttonStyle(.plain)
        .disabled(viewModel.thread?.closed == true)
        .opacity(viewModel.thread?.closed == true ? 0.5 : 1.0)
    }
}

fileprivate struct DetailViewButton: View {
    let accessibilityText: String
    let icon: String
    let action: (() -> Void)?

    var body: some View {
        Button {
            action?()
        } label: {
            Image(systemName: icon)
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
}

@available(iOS 16.4, macOS 13.3, tvOS 16.4, watchOS 9.4, *)
struct DetailTopButtonsSection_Previews: PreviewProvider {
    static var previews: some View {
        DetailTopButtonsSection()
    }
}
