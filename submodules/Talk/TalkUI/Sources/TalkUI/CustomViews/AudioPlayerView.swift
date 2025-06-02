//
//  AudioPlayerView.swift
//  TalkUI
//
//  Created by Hamed Hosseini on 10/16/21.
//

import SwiftUI
import TalkViewModels
import TalkModels

public struct AudioPlayerView: View {
    let threadVM: ThreadViewModel?
    @EnvironmentObject var audioPlayerVM: AVAudioPlayerViewModel
    @State private var playIsPressing = false
    @State private var isPressing = false
    @State private var titleIsPressing = false

    public init(threadVM: ThreadViewModel? = nil){
        self.threadVM = threadVM
    }

    public var body: some View {
        VStack(spacing: 0) {
            if !audioPlayerVM.isClosed {
                HStack() {
                    playButtonView
                    messageTitleView
                    Spacer()
                    timerView
                    closeButton
                }
                .padding(EdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 4))
                progressView
            }
        }
        .frame(height: audioPlayerVM.isClosed ? 0 : 40)
        .frame(minWidth: 0, maxWidth: .infinity)
        .clipped()
        .background(MixMaterialBackground())
        .transition(.asymmetric(insertion: .push(from: .top), removal: .move(edge: .top)))
        .animation(.easeInOut(duration: 0.15), value: audioPlayerVM.isPlaying)
        .animation(.easeInOut(duration: 0.15), value: audioPlayerVM.isClosed)
        .disabled(audioPlayerVM.isClosed)
        .onTapGesture {
            Task {
                guard let message = audioPlayerVM.message, let time = message.time, let id = message.id else { return }
                if threadVM != nil {
                    await threadVM?.historyVM.moveToTime(time, id)
                } else {
                    /// Open thread and move to the message directly if we are outside of the thread and player is still plying 
                    let threadId = message.conversation?.id ?? -1
                    AppState.shared.openThreadAndMoveToMessage(conversationId: threadId, messageId: id, messageTime: time)
                }
            }
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .global)
                .onChanged { newValue in
                    titleIsPressing = true
                }
                .onEnded { newValue in
                    titleIsPressing = false
                }
        )
    }

    var closeButton: some View {
        Image(systemName: "xmark")
            .resizable()
            .scaledToFit()
            .foregroundStyle(Color.App.textSecondary)
            .fontWeight(.bold)
            .padding(audioPlayerVM.isClosed ? 0 : 12)
            .clipShape(Rectangle())
            .opacity(isPressing ? 0.5 : 1.0)
            .contentShape(Rectangle())
            .disabled(audioPlayerVM.isClosed)
            .onTapGesture {
                withAnimation {
                    audioPlayerVM.close()
                }
            }
            .simultaneousGesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .global)
                    .onChanged { newValue in
                        isPressing = true
                    }
                    .onEnded { newValue in
                        isPressing = false
                    }
            )
            .animation(.easeInOut, value: isPressing)
    }

    private var playButtonView: some View {
        Image(systemName: audioPlayerVM.isPlaying ? "pause.fill" : "play.fill")
            .resizable()
            .scaledToFit()
            .offset(x: -8)
            .foregroundStyle(Color.App.accent)
            .fontWeight(.bold)
            .padding(audioPlayerVM.isClosed ? 0 : 12)
            .clipShape(Rectangle())
            .opacity(playIsPressing ? 0.5 : 1.0)
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation {
                    audioPlayerVM.toggle()
                }
            }
            .simultaneousGesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .global)
                    .onChanged { newValue in
                        playIsPressing = true
                    }
                    .onEnded { newValue in
                        playIsPressing = false
                    }
            )
            .animation(.easeInOut, value: playIsPressing)
    }

    private var progressView: some View {
        ProgressView(value: min(audioPlayerVM.currentTime / audioPlayerVM.duration, 1.0),
                     total: 1.0)
        .progressViewStyle(.linear)
        .scaleEffect(x: 1, y: 0.5, anchor: .center)
        .tint(Color.App.accent)
        .disabled(true)
    }

    private var messageTitleView: some View {
        Text(verbatim: audioPlayerVM.title)
            .font(.fCaption)
            .foregroundColor(Color.App.textPrimary)
            .opacity(titleIsPressing ? 0.5 : 1.0)
            .animation(.easeInOut, value: titleIsPressing)
            .disabled(true)
    }

    @ViewBuilder
    private var timerView: some View {
        if !audioPlayerVM.isClosed {
            Text(verbatim: audioPlayerVM.currentTime.timerString(locale: Language.preferredLocale) ?? "")
                .foregroundColor(.gray)
                .font(.fCaption2)
                .disabled(true)
        }
    }
}

struct AudioPlayerPreview: PreviewProvider {
    struct Preview: View {
        @ObservedObject var audioPlayerVm = AVAudioPlayerViewModel()

        var body: some View {
            AudioPlayerView()
                .environmentObject(audioPlayerVm)
                .onAppear {
                    try? audioPlayerVm.setup(fileURL: URL(string: "https://www.google.com")!, ext: "mp3", title: "Note", subtitle: "Test")
                    audioPlayerVm.isClosed = false
                }
        }
    }

    static var previews: some View {
        Preview()
    }
}
