//
//  SwipyView.swift
//  Talk
//
//  Created by hamed on 10/16/23.
//

import SwiftUI
import TalkViewModels
import TalkModels
import ChatCore
import Chat
import Swipy
import TalkUI

struct SwipyView: View {
    let container: ObjectsContainer
    private var userConfigsVM: UserConfigManagerVM { container.userConfigsVM }
    private let containerSize: CGFloat = 72
    @State private var selectedUser: UserConfig.ID?
    @State private var userConfigs: [UserConfig] = []
    @StateObject private var swipyVM: VSwipyViewModel<UserConfig> = .init([], itemSize: 72, containerSize: 72)

    var body: some View {
        HStack {
            if swipyVM.items.count > 0 {
                VSwipy(viewModel: swipyVM) { item in
                    UserConfigView(userConfig: item)
                        .frame(height: containerSize)
                        .background(Color.swipyBackground)
                        .cornerRadius(12)
                }
                .frame(height: containerSize)
                .background(Color.main.opacity(0.3))
                .cornerRadius(12)
            }
        }
        .onAppear {
            selectedUser = UserConfigManagerVM.instance.currentUserConfig?.id
            userConfigs = userConfigsVM.userConfigs
            setViewModel()
        }
        .onReceive(userConfigsVM.objectWillChange) { _ in
            if userConfigsVM.currentUserConfig?.id != selectedUser {
                selectedUser = userConfigsVM.currentUserConfig?.id
                container.reset()
                setViewModel()
            }

            if userConfigsVM.userConfigs.count != userConfigs.count {
                userConfigs = userConfigsVM.userConfigs
                setViewModel()
            }
        }
    }

    public func setViewModel() {
        if swipyVM.items.count == 0 {
            swipyVM.items = userConfigs
            swipyVM.containerSize = containerSize
            swipyVM.itemSize = containerSize
            swipyVM.selection = selectedUser
            swipyVM.onSwipe = onSwiped(item:)
            swipyVM.updateForSelectedItem()
        }
    }

    public func onSwiped(item: UserConfig) {
        if item.user.id == container.userConfigsVM.currentUserConfig?.id { return }
        ChatManager.activeInstance?.dispose()
        userConfigsVM.switchToUser(item, delegate: ChatDelegateImplementation.sharedInstance)
        container.reset()
    }
}

struct UserConfigView: View {
    let userConfig: UserConfig
    @EnvironmentObject var viewModel: SettingViewModel
    @StateObject var imageLoader = ImageLoaderViewModel()

    var body: some View {
        HStack {
            ImageLaoderView(imageLoader: imageLoader, url: userConfig.user.image, userName: userConfig.user.name)
                .id("\(userConfig.user.image ?? "")\(userConfig.user.id ?? 0)")
                .frame(width: 48, height: 48)
                .cornerRadius(24)
                .padding()
                .overlay {
                    UploadImageProfileView()
                }
                .onReceive(NotificationCenter.default.publisher(for: .connect)) { notification in
                    /// We use this to fetch the user profile image once the active instance is initialized.
                    if let status = notification.object as? ChatState, status == .connected, !imageLoader.isImageReady {
                        imageLoader.fetch(url: userConfig.user.image, userName: userConfig.user.name, size: .LARG)
                    }
                }

            VStack(alignment: .leading) {
                Text(userConfig.user.name ?? "")
                    .font(.iransansBoldSubtitle)
                    .foregroundColor(.primary)

                HStack {
                    Text(userConfig.user.cellphoneNumber ?? "")
                        .font(.iransansBody)
                        .fontDesign(.rounded)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
            Spacer()
            VStack {
                ToolbarButtonItem(imageName: "square.and.pencil", hint: "General.edit") {
                    viewModel.isEditing.toggle()
                }
                Text(Config.serverType(config: userConfig.config)?.rawValue ?? "")
                    .font(.iransansBody)
                    .foregroundColor(.green)
            }
            .padding(.trailing)
        }
        .animation(.spring(), value: viewModel.isEditing)
        .sheet(isPresented: $viewModel.showImagePicker) {
            ImagePicker(sourceType: .photoLibrary) { image, assestResources in
                viewModel.showImagePicker.toggle()
                Task {
                    await viewModel.updateProfilePicture(image: image)
                }
            }
        }
    }
}

struct UploadImageProfileView: View  {
    @EnvironmentObject var viewModel: SettingViewModel

    var body: some View {
        ZStack {
            Image(systemName: "square.and.arrow.up.fill")
                .resizable()
                .scaledToFit()
                .foregroundStyle(.white)
                .frame(width: 22, height: 22)
        }
        .frame(width: 48, height: 48)
        .background(.blue)
        .cornerRadius(24, corners: .allCorners)
        .scaleEffect(x: viewModel.isEditing ? 1 : 0.001,
                     y: viewModel.isEditing ? 1 : 0.001,
                     anchor: .center)
        .onTapGesture {
            if viewModel.isEditing {
                viewModel.showImagePicker.toggle()
            }
        }
    }
}

struct SwipyView_Previews: PreviewProvider {
    static var previews: some View {
        SwipyView(container: ObjectsContainer(delegate: ChatDelegateImplementation()))
    }
}
