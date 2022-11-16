//
//  CallsHistoryContentList.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import SwiftUI

struct CallsHistoryContentList: View {
    
    @EnvironmentObject
    var viewModel: CallsHistoryViewModel
    
    @EnvironmentObject var appState:AppState
    
    @State
    var navigateToGroupCallSelction = false
    
    var body: some View {
        VStack(spacing:0){
            ZStack{
                List {
                    ForEach(viewModel.model.calls , id:\.id) { call in
                        NavigationLink(destination: CallDetails(viewModel: .init(call: call))){
                            CallRow(call: call,viewModel: viewModel)
                                .frame(minHeight:64)
                                .onAppear {
                                    if viewModel.model.calls.last == call{
                                        viewModel.loadMore()
                                    }
                                }
                        }
                    }
                }
                .listStyle(.plain)
                
                VStack{
                    GeometryReader{ reader in
                        LoadingViewAt(isLoading:viewModel.isLoading, reader: reader)
                    }
                }
            }
        }
        .navigationTitle(Text("Calls"))
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button {
                        navigateToGroupCallSelction.toggle()
                    } label: {
                        Label {
                            Text("Start Call")
                        } icon: {
                            Image(systemName: "video.fill")
                        }
                    }
            }
        }
        NavigationLink(
            destination: GroupCallSelectionContentList(viewModel: viewModel),
            isActive: $navigateToGroupCallSelction){
                EmptyView()
            }
        
    }
}

struct CallsHistoryContentList_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = CallsHistoryViewModel()
        CallsHistoryContentList()
            .environmentObject(viewModel)
            .environmentObject(AppState.shared)
            .environmentObject(CallState.shared)
            .onAppear(){
                viewModel.setupPreview()
            }
    }
}