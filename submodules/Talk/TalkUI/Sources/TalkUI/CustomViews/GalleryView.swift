//
//  GalleryView.swift
//  TalkUI
//
//  Created by hamed on 3/14/23.
//

import TalkViewModels
import SwiftUI
import OSLog

public struct GalleryPageView: View {
    @EnvironmentObject var viewModel: GalleryViewModel
    @EnvironmentObject var offsetVM: GalleyOffsetViewModel
    @State private var showOverlayInZoom = false
    
    public init() {}
    
    public var body: some View {
        TabView(selection: $viewModel.selectedTabId) {
            ForEach(viewModel.pictures) { pictureVM in
                GalleryImageItem()
                    .environmentObject(pictureVM)
                    .tag(pictureVM.id)
                    .onAppear {
                        viewModel.onAppeared(item: pictureVM)
                    }
            }
        }
        .environment(\.layoutDirection, .leftToRight)
        .tabViewStyle(.page(indexDisplayMode: .always))
        .indexViewStyle(.page(backgroundDisplayMode: .always))
        .overlay {
            if showOverlayInZoom, let pictureVM = viewModel.pictures.first(where: { $0.id == viewModel.selectedTabId})  {
                GalleryImageItem()
                    .environmentObject(pictureVM)
            }
        }
        .onChange(of: offsetVM.endScale) { newValue in
            if newValue > 1, showOverlayInZoom == false {
                Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
                    Task { @MainActor in
                        self.showOverlayInZoom = true
                    }
                }
            } else if newValue == 1.0 {
                showOverlayInZoom = false
            }
        }
    }
}

public struct GalleryImageItem: View {
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
        .background(frameReader)
        .contentShape(Rectangle())
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
    
    @ViewBuilder
    private var textView: some View {
        if canShowTextView {
            VStack(alignment: .leading, spacing: 0){
                Spacer()
                HStack {
                    LongTextView(message)
                        .frame(minWidth: 0, maxWidth: .infinity)
                        .padding()
                        .edgesIgnoringSafeArea([.leading, .trailing, .bottom])
                }
                .background(.ultraThinMaterial)
            }
        }
    }
    
    private var message: String {
        viewModel.message.message?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
    
    private var canShowTextView: Bool {
        if let message = viewModel.message.message?.trimmingCharacters(in: .whitespacesAndNewlines), !message.isEmpty {
            return true
        } else {
            return false
        }
    }
    
    private var frameReader: some View {
        GeometryReader { proxy in
            Color.clear.onAppear {
                offsetVM.heightOfScreen = proxy.size.height
            }
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
                GalleryImageView(uiimage: image, forceLeftToRight: forceLeftToRight)
                    .transition(.opacity)
            }
        }
        .animation(.smooth, value: image)
        .onChange(of: viewModel.state) { _ in
            setImage()
        }
        .onAppear {
            setImage()
        }
    }
    
    private func setImage() {
        if viewModel.state == .completed {
            Task {
                await prepareImage(url: viewModel.fileURL)
            }
        }
    }
    
    @AppBackgroundActor
    private func prepareImage(url: URL?) async {
        if let url = url, let image = UIImage(contentsOfFile: url.path()) {
            await MainActor.run {
                self.image = image
            }
        }
    }
}

public struct GalleryImageView: View {
    let uiimage: UIImage
    @EnvironmentObject var offsetVM: GalleyOffsetViewModel
    @EnvironmentObject var appOverlayVM: AppOverlayViewModel
    @GestureState private var scaleBy: CGFloat = 1.0
    private let forceLeftToRight: Bool
    
    public init(uiimage: UIImage, forceLeftToRight: Bool) {
        self.uiimage = uiimage
        self.forceLeftToRight = forceLeftToRight
    }
    
    public var body: some View {
        Image(uiImage: uiimage)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .contentShape(Rectangle())
            .scaleEffect(scaleBy, anchor: .center)
            .scaleEffect(offsetVM.endScale, anchor: .center)
            .simultaneousGesture(doubleTapGesture.exclusively(before: zoomGesture.simultaneously(with: dragGesture)))
            .offset(offsetVM.dragOffset)
            .statusBarHidden()
    }
    
    var dragGesture: some Gesture {
        DragGesture(minimumDistance: 10, coordinateSpace: .local)
            .onChanged { value in
                if offsetVM.endScale != 1.0 {
                    offsetVM.onDragChanged(value, forcedLeftToRight: forceLeftToRight)
                }
            }
            .onEnded { value in
                if offsetVM.endScale != 1.0 {
                    offsetVM.onDragEnded(value)
                }
            }
    }
    
    var zoomGesture: some Gesture {
        MagnificationGesture()
            .updating($scaleBy) { value, state, transaction in
                state = value
                transaction.animation = .interactiveSpring()
            }
            .onEnded{ value in
                offsetVM.onMagnificationEnded(value)
            }
    }
    
    private var doubleTapGesture: some Gesture {
        TapGesture(count: 2)
            .onEnded { _ in
                offsetVM.onDoubleTapped()
            }
    }
}

struct GalleryView_Previews: PreviewProvider {
    static var previews: some View {
        GalleryImageItem()
    }
}
