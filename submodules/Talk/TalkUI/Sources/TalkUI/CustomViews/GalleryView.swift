//
//  GalleryView.swift
//  TalkUI
//
//  Created by hamed on 3/14/23.
//

import TalkViewModels
import SwiftUI
import OSLog

public struct GalleryView: View {
    @EnvironmentObject var viewModel: GalleryViewModel
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
        .onAppear {
            viewModel.fetchImage()
        }
    }

    private var progress: some View {
        CircularProgressView(percent: $viewModel.percent, config: .normal)
            .frame(maxWidth: 128)
            .frame(height: canShowDownloaingProgress ? 96 : 0)
            .padding(canShowDownloaingProgress ? 0 : 8)
            .environment(\.layoutDirection, .leftToRight)
    }

    private var canShowDownloaingProgress: Bool {
        viewModel.state == .downloading || viewModel.state == .undefined
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
        viewModel.currentImageMessage?.message?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    private var canShowTextView: Bool {
        if let message = viewModel.currentImageMessage?.message?.trimmingCharacters(in: .whitespacesAndNewlines), !message.isEmpty {
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
    @EnvironmentObject var viewModel: GalleryViewModel
    @State var image: UIImage?

    var body: some View {
        ZStack {
            if let image {
                GalleryImageView(uiimage: image, viewModel: viewModel, forceLeftToRight: forceLeftToRight)
                    .transition(.opacity)
            }
        }
        .onChange(of: viewModel.currentData) { newVlaue in
            if let data = viewModel.currentData, let uiimage = UIImage(data: data) {
                image = uiimage
            }
        }
    }
}

public struct GalleryImageView: View {
    let uiimage: UIImage
    let viewModel: GalleryViewModel?
    @EnvironmentObject var offsetVM: GalleyOffsetViewModel
    @EnvironmentObject var appOverlayVM: AppOverlayViewModel
    @GestureState private var scaleBy: CGFloat = 1.0
    private let forceLeftToRight: Bool

    public init(uiimage: UIImage, viewModel: GalleryViewModel? = nil, forceLeftToRight: Bool) {
        self.uiimage = uiimage
        self.viewModel = viewModel
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
            .animation(.easeInOut, value: scaleBy)
            .animation(.easeInOut, value: offsetVM.dragOffset)
    }

    var dragGesture: some Gesture {
        DragGesture(minimumDistance: 10, coordinateSpace: .local)
            .onChanged { value in
                offsetVM.onDragChanged(value, forcedLeftToRight: forceLeftToRight)
            }
            .onEnded { value in
                offsetVM.onDragEnded(value)
            }
    }

    var zoomGesture: some Gesture {
        MagnificationGesture()
            .updating($scaleBy) { value, state, transaction in
                if value > 1 {
                    state = value
                    transaction.animation = .interactiveSpring()
                }
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
        GalleryView()
    }
}
