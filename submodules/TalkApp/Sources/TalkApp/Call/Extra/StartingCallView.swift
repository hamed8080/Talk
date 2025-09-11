//
//  StartingCallView.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import SwiftUI
import TalkUI
import Chat

/// When receive or start call to someone you will see this screen and it will show only if call is not started.
struct StartingCallView: View {
    @EnvironmentObject var viewModel: CallViewModel
    @State private var showSetting = false
    @State private var endCallAnimationWidth: CGFloat = 52
    
    var body: some View {
        VStack() {
            Text(viewModel.call?.type == .video ? "تماس تصویری" : "تماس صوتی")
                .font(Font.fBoldCaption)
            Spacer()
            callAvatarAndName
            Spacer()
            
            HStack(spacing: 16) {
                
                Spacer()
                
                CallControlItem(iconSfSymbolName: "gear", subtitle: "", color: .gray) {
                    showSetting = true
                }
                .disabled(true)
                .allowsHitTesting(false)
                .opacity(0.2)
                
                if viewModel.call?.type == .video, viewModel.isReceiveCall {
                    CallControlItem(iconSfSymbolName: "video.fill", subtitle: "", color: .green) {
                        viewModel.answerCall(video: true, mute: false)
                    }
                }
                
                if viewModel.isReceiveCall {
                    CallControlItem(iconSfSymbolName: "phone.fill", subtitle: "", color: .green) {
                        viewModel.answerCall(video: false, mute: false)
                    }
                }
                
                ZStack {
                    Circle()
                        .fill(Color.red.opacity(0.4))
                        .frame(width: endCallAnimationWidth, height: endCallAnimationWidth)
                        .overlay(alignment: .center) {
                            CallControlItem(iconSfSymbolName: "phone.down.fill", subtitle: "", color: .red) {
                                viewModel.cancelCall()
                            }
                        }
                        .onAppear {
                            withAnimation(.easeInOut(duration: 0.8).repeatForever()) {
                                endCallAnimationWidth = 62
                            }
                        }
                }
                .frame(width: 62)
                
                Spacer()
            }
            .frame(height: 62)
        }
        .sheet(isPresented: $showSetting) {
            SettingsBeforeStart()
        }
    }
    
    @ViewBuilder
    private var callAvatarAndName: some View {
        VStack(alignment: .center, spacing: 8) {
            let id = viewModel.call?.conversation?.id
            let conversation = AppState.shared.objectsContainer.threadsVM.threads.first(where: { $0.id == id })?.toStruct()
            let creator = viewModel.call?.creator
            
            let conversationTitle = conversation?.title
            let creatorName = creator?.contactName ?? creator?.name ?? creator?.username
            
            let name = (viewModel.isReceiveCall ? creatorName : conversationTitle) ?? ""
            
            imageLoaderView(participant: creator, conversation: conversation)
                .font(.fBoldBody)
                .foregroundColor(.white)
                .frame(width: 128, height: 128)
                .background(Color(uiColor: String.getMaterialColorByCharCode(str: name)))
                .clipShape(RoundedRectangle(cornerRadius:(48)))
            
            Text(name)
                .lineLimit(1)
                .foregroundColor(Color.App.textPrimary)
                .font(.fSubheadline)
            
            let descriptionStatus = viewModel.isReceiveCall ? "\(name) در حال تماس است" : "در حال برقراری تماس"
            Text(descriptionStatus)
                .lineLimit(1)
                .foregroundColor(viewModel.isReceiveCall ? Color.App.accent : Color.App.textSecondary)
                .font(.fCaption2)
        }
    }
    
    @ViewBuilder
    private func imageLoaderView(participant: Participant? = nil, conversation: Conversation? = nil) -> some View {
        if let participant = participant {
            ImageLoaderView(participant: participant)
                .id("\(participant.image ?? "")\(participant.id ?? 0)")
        } else if let conversation = conversation {
            ImageLoaderView(conversation: conversation)
                .id("\(conversation.image ?? "")\(conversation.id ?? 0)")
        }
    }
}

struct SettingsBeforeStart: View {
    @EnvironmentObject var viewModel: CallViewModel
    
    var body: some View {
        HStack {
            
        }
    }
}

#Preview {
    StartingCallView()
        .environmentObject(MockData.callViewModel())
}
