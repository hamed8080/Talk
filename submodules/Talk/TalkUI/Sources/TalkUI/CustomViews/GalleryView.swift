//
//  GalleryView.swift
//  TalkUI
//
//  Created by hamed on 3/14/23.
//

import TalkViewModels
import SwiftUI

public struct GalleryPageView: View {
    @EnvironmentObject var viewModel: GalleryViewModel
    @StateObject var offsetVM = GalleyOffsetViewModel()
    
    public init() {}
    
    public var body: some View {
        TabView(selection: $viewModel.selectedTabId) {
            ForEach(viewModel.pictures) { pictureVM in
                PageItem()
                    .environmentObject(pictureVM)
                    .tag(pictureVM.id)
                    .onAppear {
                        viewModel.onAppeared(item: pictureVM)
                    }
            }
        }
        .environmentObject(offsetVM)
        .environment(\.layoutDirection, .leftToRight)
        .tabViewStyle(.page(indexDisplayMode: !offsetVM.isUIHidden ? .always : .never))
        .indexViewStyle(.page(backgroundDisplayMode: .always))
        .overlay { overlayToolbar }
        .animation(.easeInOut, value: offsetVM.isUIHidden)
    }
    
    @ViewBuilder
    private var overlayToolbar: some View {
        if !offsetVM.isUIHidden {
            GeometryReader { reader in
                HStack {
                    Spacer()
                    goToHistoryButton
                    downloadButton
                    dismissButton
                }
                .padding(EdgeInsets(top: 48 + reader.safeAreaInsets.top, leading: 8, bottom: 0, trailing: 8))
            }
            .environment(\.layoutDirection, .leftToRight)
        }
    }
    
    private var goToHistoryButton: some View {
        GalleryToolbarButton(imageName: "eye") {
            offsetVM.dismiss()
            viewModel.goToHistory()
            AppState.shared.objectsContainer.appOverlayVM.galleryMessage?.goToHistoryTapped?()
        }
    }
    
    private var downloadButton: some View {
        GalleryToolbarButton(imageName: "arrow.down") {
            viewModel.saveAction(iconColor: Color.App.white, messageColor: Color.App.white)
        }
        .clipShape(RoundedRectangle(cornerRadius:(20)))
    }
    
    private var dismissButton: some View {
        GalleryToolbarButton(imageName: "xmark") {
            offsetVM.dismiss()
        }
        .clipShape(RoundedRectangle(cornerRadius:(20)))
    }
}

public struct PageItem: View {
    @EnvironmentObject var viewModel: GalleryImageItemViewModel
    @EnvironmentObject var offsetVM: GalleyOffsetViewModel
    
    public init() {}
    
    public var body: some View {
        ZStack {
            progress
                .disabled(true)
            GalleryImageViewData(forceLeftToRight: true)
                .environment(\.layoutDirection, .leftToRight)
                .environmentObject(viewModel)
            textView
        }
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
        .fullScreenBackgroundView()
        .ignoresSafeArea(.all)
        .contentShape(Rectangle())
        .animation(.easeInOut, value: offsetVM.isUIHidden)
    }
    
    @ViewBuilder
    private var textView: some View {
        if canShowTextView {
            VStack(alignment: .leading, spacing: 0){
                Spacer()
                HStack {
                    LongTextView(message ?? "")
                        .frame(minWidth: 0, maxWidth: .infinity)
                        .padding()
                        .edgesIgnoringSafeArea([.leading, .trailing, .bottom])
                }
                .background(.ultraThinMaterial)
            }
        }
    }
    
    private var message: String? {
        return viewModel.message.message?.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private var canShowTextView: Bool {
        if !offsetVM.isUIHidden, let message = message?.trimmingCharacters(in: .whitespacesAndNewlines), !message.isEmpty {
            return true
        } else {
            return false
        }
    }
    
    @ViewBuilder
    private var progress: some View {
        if viewModel.state == .downloading {
            CircularProgressView(percent: $viewModel.percent, config: .normal)
                .frame(maxWidth: 128)
                .frame(height: 96)
                .padding(8)
                .environment(\.layoutDirection, .leftToRight)
                .animation(.smooth, value: viewModel.percent)
        }
    }
}

struct GalleryImageViewData: View {
    let forceLeftToRight: Bool
    @EnvironmentObject var viewModel: GalleryImageItemViewModel
    @State var image: UIImage?
    
    var body: some View {
        ZStack {
            if let image = image {
                GalleryImageView(uiimage: image)
                    .transition(.opacity)
            }
        }
        .animation(.smooth, value: image)
        .onChange(of: viewModel.state) { _ in
            Task {
                image = await viewModel.getImage()
            }
        }
        .onAppear {
            Task {
                image = await viewModel.getImage()
            }
        }
    }
}

public struct GalleryImageView: View {
    let uiimage: UIImage
    @EnvironmentObject var offsetVM: GalleyOffsetViewModel
    @State private var doubleTapLocation: CGPoint = .zero
    @State private var size: CGSize = .zero
    
    public init(uiimage: UIImage) {
        self.uiimage = uiimage
    }
    
    public var body: some View {
        Image(uiImage: uiimage)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .contentShape(Rectangle())
            .scaleEffect(offsetVM.totalScale, anchor: .center)
            .offset(offsetVM.offset)
            .gesture(offsetVM.totalScale > 1 ? dragGesture : nil)
            .simultaneousGesture(
                offsetVM.totalScale == 1 ? verticalDismissGesture : nil
            )
            .gesture(magnifyGesture)
            .simultaneousGesture(combinedGesture)
            .statusBarHidden()
            .animation(.easeInOut, value: offsetVM.totalScale)
            .animation(.easeInOut, value: offsetVM.offset)
            .background(sizeReader)
    }
    
    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 10, coordinateSpace: .local)
            .onChanged { offsetVM.onDragChanged(translation: $0.translation) }
            .onEnded { offsetVM.onDragEnded(translation: $0.translation) }
    }
    
    private var verticalDismissGesture: some Gesture {
        DragGesture(minimumDistance: 20)
            .onChanged { offsetVM.onVerticalDismissChanged(translation: $0.translation) }
            .onEnded { offsetVM.onVerticalDismissEnded(translation: $0.translation, velocity: $0.velocity) }
    }
    
    private var magnifyGesture: some Gesture {
        MagnificationGesture()
            .onChanged { offsetVM.onMagnifyChanged(scale: $0) }
            .onEnded { offsetVM.onMagnifyEnded(scale: $0) }
    }
    
    private var combinedGesture: some Gesture {
        if #available(iOS 18.0, *) {
            return doubleTapGesture
                .simultaneously(with: singleTapGesture)
                .simultaneously(with: locationGesture) /// It will prevent going to the next page on ios 17 and lower
        } else {
            return doubleTapGesture
                .simultaneously(with: singleTapGesture)
        }
    }
   
    private var singleTapGesture: some Gesture {
        TapGesture(count: 1)
            .onEnded { _ in
                offsetVM.toggleUI()
            }
    }
    
    private var doubleTapGesture: some Gesture {
        TapGesture(count: 2)
            .onEnded { offsetVM.toggleZoom(at: doubleTapLocation, in: size) }
    }
    
    private var locationGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                doubleTapLocation = value.location
            }
    }
    
    private var sizeReader: some View {
        GeometryReader { proxy in
            Color.clear.onAppear {
                size = proxy.size
            }
        }
    }
}

fileprivate struct GalleryToolbarButton: View {
    let imageName: String
    let onTapped: () -> Void
    
    var body: some View {
        Button {
            onTapped()
        } label: {
            Image(systemName: imageName)
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
}

struct GalleryView_Previews: PreviewProvider {
    static var previews: some View {
        PageItem()
    }
}
