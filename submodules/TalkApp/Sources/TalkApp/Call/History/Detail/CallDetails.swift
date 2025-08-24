//
//  CallDetails.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Additive
import SwiftUI

struct CallDetails: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject var viewModel: CallDetailViewModel

    var body: some View {
        GeometryReader { reader in
            VStack(spacing: 0) {
                ZStack {
                    VStack(spacing: 12) {
//                        VStack(alignment: .leading, spacing: 8) {
//                            if let startTime = viewModel.model.call.createTime, let date = Date(milliseconds: Int64(startTime)).timeAgoSinceDateCondense {
//                                Text("Start: \(date)")
//                            }
//
//                            if let endTime = viewModel.model.call.endTime, let date = Date(milliseconds: Int64(endTime)).timeAgoSinceDateCondense {
//                                Text("End: \(date)")
//                            }
//                            Text(viewModel.model.call.isIncomingCall(currentUserId: AppState.shared.user?.id) ? "Incoming call" : "Outgoing call")
//                            if let status = viewModel.model.call.status {
//                                Text("Status: \(String(describing: status))")
//                            }
//                        }
//                        .padding()
//                        .frame(width: reader.size.width - 36)
//                        .background(Color.white)
//                        .cornerRadius(12)

                        List {
                            Text("Call History")
                                .fontWeight(.bold)
                                .foregroundColor(Color.blue)
                            ForEach(viewModel.model.calls, id: \.id) { call in
                                CallDetailRow(call: call, viewModel: viewModel)
                                    .frame(minHeight: 64)
                                    .onAppear {
                                        if viewModel.model.calls.last == call {
                                            viewModel.loadMore()
                                        }
                                    }
                            }.onDelete(perform: { _ in
                                print("on delete")
                            })
                        }
                        .cornerRadius(24)
                        .padding([.leading, .trailing])
                        .frame(width: reader.size.width - 4)
                        .padding(.init(top: 1, leading: 0, bottom: 1, trailing: 0))
                        .listStyle(PlainListStyle())
                    }.padding(.top)
                }
                .ignoresSafeArea()
//                LoadingViewAt(isLoading: viewModel.isLoading, reader: reader)
            }
        }
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
        .background(Color.gray.opacity(0.2)
            .edgesIgnoringSafeArea(.all)
        )
    }
}

struct CallDetails_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = CallDetailViewModel(call: CallRow_Previews.call)
        CallDetails(viewModel: viewModel)
            .environmentObject(AppState.shared)
            .environmentObject(CallViewModel.shared)
    }
}
