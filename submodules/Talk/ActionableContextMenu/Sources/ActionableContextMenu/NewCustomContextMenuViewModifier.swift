//
//  NewCustomContextMenuViewModifier.swift
//
//
//  Created by hamed on 10/27/23.
//

import SwiftUI

private struct NewCustomContextMenuViewModifier<SelfView: View, ContextMenuView: View>: ViewModifier {
    @State var showOverlay: Bool = false
    @State var rowFrame: CGRect = .zero
    let menus: () -> ContextMenuView
    let selfContent: () -> SelfView
    
    init(@ViewBuilder _ selfContentCopy: @escaping () -> SelfView, @ViewBuilder _ menus: @escaping () -> ContextMenuView) {
        self.menus = menus
        self.selfContent = selfContentCopy
    }
    
    func body(content: Content) -> some View {
        ZStack {
            if !showOverlay {
                content
                    .background {
                        GeometryReader { geo in
                            Color.clear.onAppear {
                                rowFrame = geo.frame(in: .global)
                            }
                        }
                    }
                    .onLongPressGesture(minimumDuration: 0.5) {
                        withAnimation {
                            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                            showOverlay = true
                        }
                    }
            }
        }
        .fullScreenCover(isPresented: $showOverlay) {
            FullScreenConextMenuView(showOverlay: $showOverlay, contextMenu: menus) {
                selfContent()
                    .frame(maxWidth: rowFrame.width, maxHeight: rowFrame.height)
            }
        }
        .transaction { transaction in
            transaction.disablesAnimations = true
        }
    }
}

struct FullScreenConextMenuView<V: View, C: View>: View {
    @Binding var showOverlay: Bool
    @State private var showing: Bool = false
    private let view: () -> V
    private let contextMenu: () -> C
    @State private var screenSize: CGSize = .zero
    
    init(showOverlay: Binding<Bool>,
         contextMenu: @escaping () -> C,
         view: @escaping () -> V ) {
        self._showOverlay = showOverlay
        self.view = view
        self.contextMenu = contextMenu
    }
    
    var body: some View {
        ZStack {
            if #available(iOS 16.4, macOS 13.3, tvOS 16.4, watchOS 9.4, *) {
                ios16View
            } else {
                ios15View
            }
        }
        .onAppear { showing = true }
        .onDisappear { showing = false }
    }
    
    @available(iOS 16.4, macOS 13.3, tvOS 16.4, watchOS 9.4, *)
    private var ios16View: some View {
        ZStack {
          contentView
        }
        .presentationBackground(.thinMaterial)
    }
    
    private var ios15View: some View {
        ZStack {
            contentView
        }
    }
    
    @ViewBuilder
    private var contentView: some View {
        if showing {
            ZStack {
                ScrollView(.vertical) {
                    VStack(spacing: 8) {
                        view()
                        contextMenu()
                            .simultaneousGesture(
                                TapGesture().onEnded {
                                    withAnimation {
                                        showOverlay = false
                                    }
                                }
                            )
                        Spacer()
                    }
                    .offset(y: (screenSize.height / 2) - 100)
                }
                .frame(minWidth: 0, maxWidth: .infinity)
            }
            .contentShape(Rectangle())
            .background {
                GeometryReader { geo in
                    Color.clear.onAppear {
                        screenSize = geo.size
                    }
                }
            }
            .transition(.opacity.animation(.easeInOut))
            .padding()
            .onTapGesture {
                // Dismiss the overlay
                showOverlay = false
            }
        }
    }
}

public extension View {
    func newCustomContextMenu<SelfView: View, MenuView: View>(selfView: @escaping () -> SelfView, @ViewBuilder menus: @escaping () -> MenuView) -> some View {
        return modifier(NewCustomContextMenuViewModifier(selfView, menus))
    }
}
