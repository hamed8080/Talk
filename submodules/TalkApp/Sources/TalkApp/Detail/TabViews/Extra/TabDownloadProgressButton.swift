//
//  TabDownloadProgressButton.swift
//  TalkApp
//
//  Created by Hamed Hosseini on 7/10/25.
//

import SwiftUI
import TalkViewModels

struct TabDownloadProgressButton: View {
    @EnvironmentObject var rowModel: TabRowModel
    @EnvironmentObject var viewModel: ThreadDetailViewModel
    
    var body: some View {
        Button {
            rowModel.onTap(viewModel: viewModel)
        } label: {
            ZStack {
                Image(systemName: rowModel.stateIcon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 12, height: 12)
                    .foregroundStyle(Color.App.white)
                    .fontWeight(.bold)
                
                if rowModel.state.state == .paused || rowModel.state.state == .downloading {
                    Circle()
                        .trim(from: 0.0, to: min(rowModel.state.progress, 1.0))
                        .stroke(style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                        .foregroundColor(Color.App.white)
                        .rotationEffect(Angle(degrees: 270))
                        .frame(width: 28, height: 28)
                        .environment(\.layoutDirection, .leftToRight)
                        .rotationEffect(.degrees(rowModel.degree))
                }
            }
            .frame(width: 36, height: 36)
            .background(rowModel.state.state == .error ? Color.red : Color.App.accent)
            .clipShape(RoundedRectangle(cornerRadius:(36 / 2)))
            .environment(\.layoutDirection, .leftToRight)
        }
    }
}
