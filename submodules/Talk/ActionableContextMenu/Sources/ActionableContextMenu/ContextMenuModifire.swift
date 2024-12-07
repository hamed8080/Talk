//
//  ContextMenuModifire.swift
//
//
//  Created by hamed on 10/27/23.
//

import Foundation
import SwiftUI
import OSLog

struct ContextMenuModifire<V: View>: ViewModifier {
    private let logger = Logger(subsystem: "ActionableContextMenu", category: "ContextMenuModifire")
    @EnvironmentObject var viewModel: ContextMenuModel
    @State var scale: CGFloat = 1.0
    let addedX: CGFloat
    let disable: Bool
    @GestureState var isTouched: Bool = false
    @GestureState var isTouchedLocalPosition: Bool = false
    let menus: () -> V
    let root: any View
    var id: Int?
    @State var itemWidth: CGFloat = 0
    @State var globalFrame: CGRect = .zero
    let onTap: (() -> Void)?
    
    init(id: Int?, root: any View, addedX: CGFloat = 48, disable: Bool = false, onTap: (() -> Void)? = nil, @ViewBuilder menus: @escaping () -> V) {
        self.id = id
        self.onTap = onTap
        self.root = root
        self.menus = menus
        self.addedX = addedX
        self.disable = disable
    }
    
    func body(content: Content) -> some View {
        if #available(iOS 17.0, macOS 10.15, tvOS 17.0, watchOS 6.0, *) {
            return ios17(content: content)
        } else {
            return ios15(content: content)
        }
    }
    
    private func ios17(content: Content) -> some View {
        content
            .background(frameReader)
            .scaleEffect(x: scale, y: scale, anchor: .center)
            .gesture(tapgesture)
            .simultaneousGesture(postionGesture.simultaneously(with: localPostionGesture), including: .gesture)
            .onChange(of: viewModel.isPresented) { _ in
                startScaleAnimation()
            }
    }
    
    private func ios15(content: Content) -> some View {
        content
            .background(frameReader)
            .scaleEffect(x: scale, y: scale, anchor: .center)
            .gesture(tapgesture)
            .gesture(postionGesture.simultaneously(with: localPostionGesture))
            .onChange(of: viewModel.isPresented) { _ in
                startScaleAnimation()
            }
    }
    
    ///For scrolling it is need to have this
    var tapgesture: some Gesture {
        TapGesture(count: 1)
            .onEnded { _ in
                onTap?()
            }
    }
    
    var postionGesture: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .global)
            .updating($isTouched) { value, state, transaction in
                state = true
            }
            .onChanged { value in
                globalPositionChanged(value)
            }
    }
    
    var localPostionGesture: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .local)
            .updating($isTouchedLocalPosition) { value, state, transaction in
                state = true
                startTimerOnPress()
            }
            .onChanged { value in
                localPositionChanged(value)
            }
    }
    
    func isPastTheMargin(first: CGFloat, newValue: CGFloat) -> Bool {
        let padding: CGFloat = 14
        return newValue > first + padding || newValue < first - padding
    }
    
    var frameReader: some View {
        GeometryReader { reader in
            Color.clear.onAppear {
                setFrames(reader)
            }
        }
    }
    
    private func globalPositionChanged(_ value: GestureStateGesture<DragGesture, Bool>.Value) {
        if disable { return }
        let width = value.translation.width
        let height = value.translation.height
        if !viewModel.isPresented, width > -2 && width < 2 {
            viewModel.globalPosition = value.location
            log("global touched value location x: \(value.location.x) y: \(value.location.y)")
        }
    }
    
    private func localPositionChanged(_ value: GestureStateGesture<DragGesture, Bool>.Value) {
        if disable { return }
        /// We check this to prevent rapidally update the UI.
        let beforeX = viewModel.localPosition?.x ?? 0
        let beforeY = viewModel.localPosition?.y ?? 0
        // This line prevent the ui move around
        if viewModel.isPresented && viewModel.localPosition?.x ?? 0 > 0 { return }
        if isPastTheMargin(first: beforeX, newValue: value.location.x) || isPastTheMargin(first: beforeY, newValue: value.location.y) {
            viewModel.localPosition = value.location
            log("local touched value location x: \(value.location.x) y:\(value.location.y)")
        }
    }
    
    private func startTimerOnPress() {
        Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { _ in
            // Check if still after 0.3 second the user is holding finger down if not we do nothing.
            Task { @MainActor in
                if isTouchedLocalPosition {
                    showWithAnimation()
                }
            }
        }
    }
    
    private func showWithAnimation() {
        var transaction = Transaction()
        transaction.animation = Animation.easeInOut(duration: 0.2)
        withTransaction(transaction) {
            scale = 0.9
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation {
                    showMenu()
                }
            }
        }
    }
    
    private func showMenu() {
        viewModel.isPresented = true
        viewModel.menus = AnyView(menus().environmentObject(viewModel))
        scale = 1.05
        viewModel.presentedId = id
        viewModel.globalFrame = globalFrame
        viewModel.addedX = addedX
        viewModel.mainView = AnyView(root)
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
    }
    
    private func startScaleAnimation() {
        var transaction = Transaction()
        transaction.animation = .easeInOut(duration: 0.2)
        withTransaction(transaction) {
            if viewModel.isPresented == false {
                scale = 1.0
            }
        }
    }
    
    private func setFrames(_ reader: GeometryProxy) {
        let globalFrame = reader.frame(in: .global)
        let itemWidth = reader.frame(in: .local).width
        /// Check for repetitive update.
        if self.globalFrame.width != globalFrame.width && self.globalFrame.height != globalFrame.height {
            DispatchQueue.main.async {
                /// We must check the presented is equal to the id of the initialized modifier, unless the viewModel.item Width will be set to another wrong view width.
                if viewModel.isPresented, viewModel.presentedId == id {
                    viewModel.itemWidth = itemWidth
                }
                self.globalFrame = globalFrame
                log("globalFrame width: \(globalFrame.width) height: \(globalFrame.height)  originX: \(globalFrame.origin.x) originY: \(globalFrame.origin.y)")
            }
        }
    }
    
    private func log(_ string: String) {
#if DEBUG
        logger.info("\(string)")
#endif
    }
}

public extension View {
    func customContextMenu<V: View>(id: Int?, self: any View, addedX: CGFloat = 48, disable: Bool = false, onTap: (() -> Void)? = nil, @ViewBuilder menus: @escaping () -> V) -> some View {
        modifier(ContextMenuModifire(id: id, root: self, addedX: addedX, disable: disable, onTap: onTap, menus: menus))
    }
}
