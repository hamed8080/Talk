//
//  StartedCallView.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import SwiftUI

struct StartedCallView: View {
    @EnvironmentObject var viewModel: CallViewModel
    @Binding var showDetailPanel: Bool
    @State var location: CGPoint = .init(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height - 164)
    
    private var gridColumns: [GridItem] {
        let videoCount = viewModel.activeUsers.count
        return Array(repeating: GridItem(.flexible(), spacing: 16), count: videoCount <= 2 ? 1 : 2)
    }
    
    private var simpleDrag: some Gesture {
        DragGesture()
            .onChanged { value in
                self.location = value.location
            }
    }

    var body: some View {
        CenterAciveUserRTCView()
        if isIpad {
            listLargeIpadParticipants
            GeometryReader { reader in
                CallStartedActionsView(showDetailPanel: $showDetailPanel)
                    .position(location)
                    .gesture(
                        simpleDrag.simultaneously(with: simpleDrag)
                    )
                    .onAppear {
                        location = CGPoint(x: reader.size.width / 2, y: reader.size.height - 128)
                    }
            }
        } else {
            VStack {
                Spacer()
                listSmallCallParticipants
                CallStartedActionsView(showDetailPanel: $showDetailPanel)
            }
        }
    }
    
    @ViewBuilder var listSmallCallParticipants: some View {
        ScrollView(.horizontal) {
            LazyHGrid(rows: [GridItem(.flexible(), spacing: 0)], spacing: 0) {
                ForEach(viewModel.activeUsers) { userrtc in
                    UserRTCView(userRTC: userrtc)
                        .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                        .onTapGesture {
                            viewModel.activeLargeCall = userrtc
                        }
                }
                .padding([.all], isIpad ? 8 : 6)
            }
        }
        .frame(height: viewModel.defaultCellHieght + 25) // +25 for when a user start talking showing frame
    }
    
    @ViewBuilder var listLargeIpadParticipants: some View {
        if viewModel.activeUsers.count <= 2 {
            HStack(spacing: 16) {
                ForEach(viewModel.activeUsers) { userrtc in
                    UserRTCView(userRTC: userrtc)
                        .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                }
            }
            .padding([.leading, .trailing], 12)
        } else {
            ScrollView {
                LazyVGrid(columns: gridColumns, spacing: 16) {
                    ForEach(viewModel.activeUsers) { userrtc in
                        UserRTCView(userRTC: userrtc)
                            .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                    }
                }
                .padding([.leading, .trailing], 12)
            }
        }
    }
    
    var isIpad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
}
