//
//  CallParticipantListView.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 6/5/21.
//

import Chat
import SwiftUI

struct CallParticipantListView: View {
    @EnvironmentObject var viewModel: CallViewModel

    var body: some View {
        List {
//            Section("Online") {
//                ForEach(viewModel.activeUsers, id: \.id) { userRTC in
//                    CallParticipantRow(userRTC: userRTC)
//                }
//                .listRowBackground(Color.clear)
//            }
//
//            Section("Offlines") {
//                ForEach(viewModel.offlineParticipants, id: \.id) { participant in
//                    OfflineParticipantRow(participant: participant)
//                }
//                .listRowBackground(Color.clear)
//            }
//            ListLoadingView(isLoading: $viewModel.isLoading)
        }
        .listStyle(.plain)
        .onAppear {
            viewModel.getParticipants()
        }
    }
}

struct CallParticipantContentList_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = CallViewModel.shared
        CallParticipantListView()
            .environmentObject(viewModel)
            .onAppear {
                viewModel.objectWillChange.send()
            }
    }
}
