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
                            if viewModel.canDismiss {
                                viewModel.dialogView = nil
                            }
                        }
                }
                content()
                    .transition(viewModel.transition)
                    .clipShape(RoundedRectangle(cornerRadius:(viewModel.radius)))
            }
        }
        .ignoresSafeArea(.all)
        .animation(animtion, value: viewModel.isPresented)
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
                viewModel.isPresented = true
            }
        }
    }
    
    static var previews: some View {
        Preview()
    }
}
