//
//  AppOverlayView.swift
//  TalkUI
//
//  Created by Hamed Hosseini on 10/16/21.
//

import SwiftUI
import TalkViewModels

public struct AppOverlayView<Content>: View where Content: View {
    @EnvironmentObject var viewModel: AppOverlayViewModel
    @EnvironmentObject var galleryOffsetVM: GalleyOffsetViewModel
    let content: () -> Content
    let onDismiss: (() -> Void)?
    
    public init(onDismiss: (() -> Void)?, @ViewBuilder content: @escaping () -> Content) {
        self.content = content
        self.onDismiss = onDismiss
    }
    
    public var body: some View {
        ZStack {
            if viewModel.isPresented {
                if !viewModel.isError && !viewModel.isToast {
                    Rectangle()
                        .fill(Color.clear)
                        .background(.ultraThinMaterial)
                        .onTapGesture {
                            viewModel.dialogView = nil
                        }
                }
                content()
                    .transition(viewModel.transition)
                    .clipShape(RoundedRectangle(cornerRadius:(viewModel.radius)))
            }
            
            if viewModel.showCloseButton && viewModel.isPresented && !viewModel.isError {
                DismissAppOverlayButton()
            }
        }
        .ignoresSafeArea(.all)
        .offset(y: galleryOffsetVM.containerYOffset)
        .animation(.easeInOut, value: galleryOffsetVM.containerYOffset)
        .animation(animtion, value: viewModel.isPresented)
        .simultaneousGesture(dragGesture)
        .onChange(of: viewModel.isPresented) { newValue in
            if newValue == false {
                onDismiss?()
            }
        }
    }
    
    var animtion: Animation {
        if viewModel.isPresented && !viewModel.isError {
            return Animation.interactiveSpring(response: 0.2, dampingFraction: 0.6, blendDuration: 0.2)
        } else {
            return Animation.easeInOut
        }
    }
    
    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                onDragGesture(value)
            }
            .onEnded { endValue in
                onDragGesture(endValue)
            }
    }
    
    private func onDragGesture(_ value: DragGesture.Value) {
        let tr = value.translation
        let width = abs(tr.width)
        let height = tr.height
        guard case .gallery(let message) = viewModel.type else {
            // If it's NOT .gallery, return early
            return
        }
        if width < 10 || height > 100 {
            galleryOffsetVM.onContainerDragEnded(value)
        }
    }
}

struct DismissAppOverlayButton: View {
    @EnvironmentObject var galleryOffsetVM: GalleyOffsetViewModel
    
    var body: some View {
        GeometryReader { reader in
            VStack {
                Button {
                    galleryOffsetVM.dismiss()
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
                .frame(width: 40, height: 40)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius:(20)))
            }
            .padding(EdgeInsets(top: 48 + reader.safeAreaInsets.top, leading: 8, bottom: 0, trailing: 0))
        }
    }
}

struct AppOverlayView_Previews: PreviewProvider {
    struct Preview: View {
        @StateObject var viewModel = AppOverlayViewModel()
        
        var body: some View {
            AppOverlayView() {
                //
            } content: {
                Text("TEST")
            }
            .environmentObject(viewModel)
            .onAppear {
                viewModel.showCloseButton = true
                viewModel.isPresented = true
            }
        }
    }
    
    static var previews: some View {
        Preview()
    }
}
