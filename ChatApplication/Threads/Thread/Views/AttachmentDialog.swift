//
//  AttachmentDialog.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 11/23/21.
//

import AdditiveUI
import ChatAppModels
import ChatAppUI
import ChatAppViewModels
import SwiftUI

struct AttachmentDialog: View {
    private var threadVM: ThreadViewModel? { viewModel.threadViewModel }
    let viewModel: ActionSheetViewModel

    var body: some View {
        if let threadVM {
            VStack(alignment: .leading, spacing: 24) {
                PhotoGridView(viewModel: viewModel)
                Spacer()
                MutableAttachmentDialog(threadVM: threadVM)
            }
            .environmentObject(viewModel)
        }
    }
}

struct MutableAttachmentDialog: View {
    @EnvironmentObject var viewModel: ActionSheetViewModel
    let threadVM: ThreadViewModel
    @State var text: String = ""

    var body: some View {
        let count = viewModel.selectedImageItems.count
        let text = count > 0 ? "\(count) selected" : "Nothing Has been selected."
        Text(verbatim: text)
            .multilineTextAlignment(.center)
            .foregroundColor(Color(uiColor: .systemGray))
            .font(.iransansCaption)
            .frame(minWidth: 0, maxWidth: .infinity)
            .animation(.easeInOut, value: viewModel.selectedImageItems.count)
        if viewModel.selectedImageItems.count > 0 {
            SendTextViewWithButtons {
                viewModel.sendSelectedPhotos()
                threadVM.sheetType = nil
                threadVM.animatableObjectWillChange()
            } onCancel: {
                viewModel.refresh()
                threadVM.sheetType = nil
                threadVM.animatableObjectWillChange()
            }
            .environmentObject(threadVM)
        } else {
            buttons
        }
    }

    @ViewBuilder var buttons: some View {
        VStack(alignment: .leading, spacing: 24) {
            Button {
                threadVM.sheetType = .galleryPicker
                threadVM.animatableObjectWillChange()
            } label: {
                Label("Photo or Video", systemImage: "photo")
            }

            Button {
                threadVM.sheetType = .filePicker
                threadVM.animatableObjectWillChange()
            } label: {
                Label("File", systemImage: "doc")
            }

            Button {
                threadVM.sheetType = .locationPicker
                threadVM.animatableObjectWillChange()
            } label: {
                Label("Location", systemImage: "location.viewfinder")
            }

            Button {
                threadVM.sheetType = .contactPicker
                threadVM.animatableObjectWillChange()
            } label: {
                Label("Contact", systemImage: "person.2.crop.square.stack")
            }
        }
        .font(.iransansBody)
        .padding()
    }
}

struct PhotoGridView: View {
    let viewModel: ActionSheetViewModel
    @Environment(\.horizontalSizeClass) var size

    var body: some View {
        ScrollView(.vertical) {
            LazyVGrid(columns: Array(repeating: .init(.flexible(minimum: 96, maximum: 128), spacing: 0), count: size == .compact ? 4 : 7), spacing: 4) {
                AttachmentMessageList()
            }
        }
        .onDisappear {
            viewModel.refresh()
        }
        .task {
            await viewModel.loadImages()
        }
    }
}

struct AttachmentMessageList: View {
    @EnvironmentObject var viewModel: ActionSheetViewModel

    var body: some View {
        ForEach(viewModel.allImageItems) { item in
            AttachmentImageView(viewModel: viewModel, item: item)
        }
    }
}

struct AttachmentImageView: View {
    var viewModel: ActionSheetViewModel
    var item: ImageItem
    var image: UIImage { UIImage(data: item.imageData)! }
    @State private var isSelected: Bool = false

    var body: some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .frame(width: 96, height: 96)
            .clipped()
            .transition(.scale.animation(.spring(response: 0.5, dampingFraction: 0.5, blendDuration: 0.5)))
            .overlay {
                selectRadio
            }
            .onAppear {
                if viewModel.allImageItems.last?.id == item.id {
                    viewModel.loadMore()
                }
            }
            .onTapGesture {
                Task {
                    await viewModel.toggleSelectedImage(item)
                    withAnimation(!isSelected ? .spring(response: 0.5, dampingFraction: 0.5, blendDuration: 0.2) : .linear) {
                        isSelected = viewModel.selectedImageItems.contains(where: { $0.phAsset === item.phAsset })
                    }
                }
            }
    }

    @ViewBuilder var selectRadio: some View {
        ZStack {
            Image(systemName: "checkmark.circle.fill")
                .font(.title)
                .scaleEffect(x: isSelected ? 1 : 0.001, y: isSelected ? 1 : 0.001, anchor: .center)
                .foregroundColor(Color.blue)

            Image(systemName: "circle")
                .font(.title)
                .foregroundColor(Color.blue)
        }
        .frame(width: isSelected ? 22 : 0.001, height: isSelected ? 22 : 0.001, alignment: .center)
        .padding(isSelected ? 24 : 0.001)
        .scaleEffect(x: isSelected ? 1.0 : 0.001, y: isSelected ? 1.0 : 0.001, anchor: .center)
        .disabled(true)
        .allowsHitTesting(false)
    }
}

struct AttachmentDialog_Previews: PreviewProvider {
    static var viewModel: ActionSheetViewModel {
        let vm = ThreadViewModel(thread: MockData.thread)
        let viewModel = ActionSheetViewModel()
        viewModel.threadViewModel = vm
        return viewModel
    }

    static var previews: some View {
        AttachmentDialog(viewModel: viewModel)
    }
}
