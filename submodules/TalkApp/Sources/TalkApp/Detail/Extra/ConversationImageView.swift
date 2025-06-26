//
//  ConversationImageView.swift
//  TalkApp
//
//  Created by Hamed Hosseini on 6/26/25.
//

import SwiftUI
import TalkViewModels
import TalkUI

struct ConversationImageView: View {
    let image: UIImage
    @StateObject var offsetVM = GalleyOffsetViewModel()
    
    var body: some View {
        ZStack {
            GalleryImageView(uiimage: image)
                .environmentObject(offsetVM)
            dismissButton
        }
        .environment(\.layoutDirection, .leftToRight)
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
        .fullScreenBackgroundView()
        .ignoresSafeArea(.all)
    }
    
    private var dismissButton: some View {
        GeometryReader { reader in
            HStack {
                Spacer()
                Button {
                    offsetVM.dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                        .padding()
                        .foregroundColor(Color.App.accent)
                        .aspectRatio(contentMode: .fit)
                        .contentShape(Rectangle())
                }
                
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius:(20)))
            }
            .padding(EdgeInsets(top: 48 + reader.safeAreaInsets.top, leading: 8, bottom: 0, trailing: 8))
        }
    }
}
