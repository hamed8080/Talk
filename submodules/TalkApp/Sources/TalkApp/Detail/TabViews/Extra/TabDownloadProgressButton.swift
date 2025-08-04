//
//  TabDownloadProgressButton.swift
//  TalkApp
//
//  Created by Hamed Hosseini on 7/10/25.
//

import SwiftUI
import TalkViewModels
import AVFoundation

struct TabDownloadProgressButton: View {
    @EnvironmentObject var rowModel: TabRowModel
    @EnvironmentObject var viewModel: ThreadDetailViewModel
    
    var body: some View {
        Button {
            rowModel.onTap(viewModel: viewModel)
        } label: {
            ZStack {
                if rowModel.state.state == .completed, rowModel.message.isAudio, let item = rowModel.itemPlayer {
                    PlayerAudioCircle()
                        .environmentObject(item)
                } else {
                    DownloadCircle()
                        .environmentObject(rowModel)
                }
            }
            .frame(width: 36, height: 36)
            .background(rowModel.state.state == .error ? Color.red : Color.App.accent)
            .clipShape(RoundedRectangle(cornerRadius:(36 / 2)))
            .environment(\.layoutDirection, .leftToRight)
        }
    }
}

fileprivate struct DownloadCircle: View {
    @EnvironmentObject var rowModel: TabRowModel
    
    var body: some View {
        Image(systemName: rowModel.stateIcon)
            .resizable()
            .scaledToFit()
            .frame(width: 12, height: 12)
            .foregroundStyle(Color.App.white)
            .fontWeight(.bold)
        
        if rowModel.state.state == .paused || rowModel.state.state == .downloading {
            Circle()
                .trim(from: 0.0, to: min(rowModel.state.progress, 1.0))
                .stroke(style: StrokeStyle(lineWidth: 4.0, lineCap: .round, lineJoin: .round))
                .frame(width: 36, height: 36)
                .foregroundColor(Color.App.textPrimary)
                .rotationEffect(Angle(degrees: 270))
                .environment(\.layoutDirection, .leftToRight)
                .rotationEffect(.degrees(rowModel.degree))
        }
    }
}

fileprivate struct PlayerAudioCircle: View {
    @EnvironmentObject var item: AVAudioPlayerItem
    @State var artwork: UIImage?
    
    var body: some View {
        if let artwork = artwork {
            Image(uiImage: artwork)
                .resizable()
                .scaledToFit()
                .frame(width: 36, height: 36)
                .clipShape(RoundedRectangle(cornerRadius:(36 / 2)))
                .overlay {
                    Circle()
                        .fill(.gray.opacity(0.3))
                        .frame(width: 36, height: 36)
                        .clipShape(RoundedRectangle(cornerRadius:(36 / 2)))
                }
        }
        
        Image(systemName: item.isPlaying ? "pause.fill" : "play.fill")
            .resizable()
            .scaledToFit()
            .frame(width: 12, height: 12)
            .foregroundStyle(Color.App.white)
            .fontWeight(.bold)
        
        Circle()
            .trim(from: 0.0, to: item.duration > 0.0 ? min(item.currentTime / item.duration, 1.0) : 0.0)
            .stroke(style: StrokeStyle(lineWidth: 4.0, lineCap: .round, lineJoin: .round))
            .frame(width: 36, height: 36)
            .foregroundStyle(Color.App.textPrimary)
            .rotationEffect(Angle(degrees: 270))
            .environment(\.layoutDirection, .leftToRight)
            .task {
                await fetchArtwork()
            }
    }
    
    @MainActor
    private func fetchArtwork() async {
        if let artworkData = try? await item.artworkMetadata?.load(.dataValue), let image = UIImage(data: artworkData) {
            self.artwork = image
        }
    }
}
