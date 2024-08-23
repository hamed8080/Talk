//
//  CustomContextMenuContainer.swift
//  
//
//  Created by hamed on 10/27/23.
//

import Foundation
import SwiftUI
import OSLog

struct CustomContextMenuContainer: ViewModifier {
    let viewModel: ContextMenuModel = .init()

    func body(content: Content) -> some View {
        ZStack(alignment: .leading) {
            content
            MutableContextMenuOverlayView()
        }
        .environmentObject(viewModel)
    }
}

struct MutableContextMenuOverlayView: View {
    @EnvironmentObject var viewModel: ContextMenuModel
    private let logger = Logger(subsystem: "ActionableContextMenu", category: "CustomContextMenuContainer")

    var body: some View {
        ZStack(alignment: .leading) {
            Rectangle()
                .fill(Color.clear)
                .background(.ultraThinMaterial)
                .onTapGesture(perform: viewModel.hide)
                .transition(.opacity.animation(.easeInOut(duration: 0.3)))
                .background(containerSafeAreaReader)
                .opacity(viewModel.isPresented ? 1.0 : 0.0)
            if viewModel.isPresented {
                if let mainView = viewModel.mainView {
                    mainView
                        .scaleEffect(x: viewModel.scale, y: viewModel.scale, anchor: .center)
                        .position(x: viewModel.x, y: viewModel.y) /// center of the view
                        .onAppear(perform: viewModel.animateOnAppear)
                        .transition(.scale.animation(.easeInOut(duration: 0.2)))
                }

                viewModel.menus
                    .background(stackSizeReader)
                    .position(x: viewModel.stackX, y: viewModel.stackY)
                    .transition(.scale.animation(.easeIn(duration: 0.2)))
            }
        }
        .environment(\.layoutDirection, .leftToRight)
    }

    var containerSafeAreaReader: some View {
        GeometryReader { reader in
            Color.clear.onAppear {
                let reader  = reader
                viewModel.containerSize = reader.size
                viewModel.safeAreaInsets = reader.safeAreaInsets
#if DEBUG
                logger.info("container size width: \(viewModel.containerSize.width) height: \(viewModel.containerSize.height)")
                logger.info("container safeAreaInsets Top:\(viewModel.safeAreaInsets.top)")
                logger.info("container safeAreaInsets Bottom:\(viewModel.safeAreaInsets.bottom)")
#endif
            }
        }
    }

    var stackSizeReader: some View {
        GeometryReader { reader in
            Color.clear.onAppear {
                DispatchQueue.main.async {
                    viewModel.stackSize = reader.size
                }
            }
        }
    }
}

public extension View {
    func contextMenuContainer() -> some View {
        modifier(CustomContextMenuContainer())
    }
}
