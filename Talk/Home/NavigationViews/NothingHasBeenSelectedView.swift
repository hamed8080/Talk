//
//  NothingHasBeenSelectedView.swift
//  Talk
//
//  Created by hamed on 9/14/23.
//

import SwiftUI
import TalkViewModels
import TalkUI

struct NothingHasBeenSelectedView: View {
    let contactsVM: ContactsViewModel
    @State private var showBuilder = false

    var body: some View {
        ZStack {
            VStack(spacing: 12) {
                Image("talk_first_page")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 320, height: 222)
                VStack(spacing: 16) {
                    Text("General.nothingSelectedConversation")
                        .font(.fSubheadline)
                        .foregroundColor(Color.App.textSecondary)
                        .multilineTextAlignment(.center)
                        .frame(minWidth: 220)
                    Button {
                        showBuilder.toggle()
                    } label: {
                        HStack(spacing: 16) {
                            Image(systemName: "plus")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 16, height: 16)
                            Text("General.createAConversation")
                        }
                    }
                    .fixedSize()
                    .font(.fBoldBody)
                    .padding(EdgeInsets(top: 12, leading: 24, bottom: 12, trailing: 24))
                    .background(Color.App.bgSecondary)
                    .clipShape(RoundedRectangle(cornerRadius:(12)))
                    .foregroundStyle(Color.App.textPrimary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .inset(by: 0.5)
                            .stroke(Color.App.textSecondary, lineWidth: 1)
                    )
                }
            }
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
            .padding(EdgeInsets(top: 96, leading: 96, bottom: 96, trailing: 96))
            .background(MixMaterialBackground().ignoresSafeArea())
        }
        .sheet(isPresented: $showBuilder) {
            StartThreadContactPickerView()
        }
    }
}

struct NothingHasBeenSelectedView_Previews: PreviewProvider {
    static var previews: some View {
        NothingHasBeenSelectedView(contactsVM: .init())
    }
}
