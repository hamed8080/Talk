//
//  ImageLoaderView.swift
//  TalkUI
//
//  Created by hamed on 1/18/23.
//

import Chat
import Foundation
import SwiftUI
import TalkModels
import TalkViewModels
import ChatDTO
import Combine

public struct ImageLoaderView: View {
    @StateObject var imageLoader: ImageLoaderViewModel
    let contentMode: ContentMode
    let textFont: Font

    public init(imageLoader: ImageLoaderViewModel,
                contentMode: ContentMode = .fill,
                textFont: Font = .fBody
    ) {
        self.textFont = textFont
        self.contentMode = contentMode
        self._imageLoader = StateObject(wrappedValue: imageLoader)
    }

    public var body: some View {
        ZStack {
            if !imageLoader.isImageReady {
                Text(String(imageLoader.config.userName ?? " "))
                    .font(textFont)
            } else if imageLoader.isImageReady {
                Image(uiImage: imageLoader.image)
                    .interpolation(.none)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            }
        }
        .animation(.easeInOut, value: imageLoader.image)
        .animation(.easeInOut, value: imageLoader.isImageReady)
        .onAppear {
            if !imageLoader.isImageReady {
                imageLoader.fetch()
            }
        }
    }
}

public final class ImageLoaderUIView: UIImageView {
    public var imageLoaderVM: ImageLoaderViewModel?
    private var cancelable: AnyCancellable?

    public override init(frame: CGRect) {
        super.init(frame: frame)
        configureView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureView() {
        translatesAutoresizingMaskIntoConstraints = false
        contentMode = .scaleAspectFill
    }

    public func setValues(config: ImageLoaderConfig) {
        if imageLoaderVM == nil {
            imageLoaderVM = .init(.init(config: config))
            setupObserver()
            Task {
                await imageLoaderVM?.fetch()
            }
        }
    }

    private func setupObserver() {
        cancelable = imageLoaderVM?.$image.sink { [weak self] _ in
            self?.setImage()
        }
    }

    private func setImage() {
        image = imageLoaderVM?.image
    }
}

struct ImageLoaderUIViewWapper: UIViewRepresentable {
    let config: ImageLoaderConfig

    func makeUIView(context: Context) -> some UIView {
        let view = ImageLoaderUIView(frame: .zero)
        return view
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {

    }
}

struct ImageLoaderView_Previews: PreviewProvider {
    struct Preview: View {
        let config = ImageLoaderConfig(url: "https://media.gcflearnfree.org/ctassets/topics/246/share_size_large.jpg", userName: "Hamed")
        var body: some View {
            ImageLoaderUIViewWapper(config: config)
        }
    }

    static var previews: some View {
        Preview()
    }
}
