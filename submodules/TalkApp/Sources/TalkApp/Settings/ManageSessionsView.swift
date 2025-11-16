//
//  ManageSessionsView.swift
//  Talk
//
//  Created by Hamed Hosseini on 12/14/24.
//

import SwiftUI
import TalkModels
import TalkExtensions
import TalkViewModels
import TalkUI
import Lottie

struct ManageSessionsView: View {
    @StateObject private var viewModel = ManageSessionsViewModel()
    @State private var width: CGFloat = 0
    
    var body: some View {
        List {
            removeAllSessions
            rows
            loadingView
        }
        .environment(\.defaultMinListRowHeight, 8)
        .font(Font.normal(.subheadline))
        .background(Color.App.bgPrimary)
        .listStyle(.plain)
        .normalToolbarView(title: "Settings.ManageSessions.title", innerBack: true, type: String.self)
        .animation(.easeInOut, value: viewModel.sessions.count)
        .animation(.easeInOut, value: viewModel.isLoading)
        .task {
            do {
                try await viewModel.getDevices()
            } catch {
#if DEBUG
                print("Error fetching device list: \(error)")
#endif
            }
        }
        .background {
            sizeReader
        }
    }
    
    @ViewBuilder
    private var rows: some View {
        let lastId = viewModel.sessions.last?.id
        ForEach(viewModel.sessions, id: \.id) { session in
            DeviceSessionRow(session: session, width: width)
                .id(session.id)
                .environmentObject(viewModel)
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .onAppear() {
                    if session.id == lastId {
                        Task {
                            try? await viewModel.loadMore()
                        }
                    }
                }
        }
    }
    
    @ViewBuilder
    private var removeAllSessions: some View {
        VStack(alignment: .center) {
            Text("ManageSessions.removeAllDescription".bundleLocalized())
            Button("ManageSessions.removeAll".bundleLocalized()) {
                AppState.shared.objectsContainer.appOverlayVM.dialogView = AnyView(
                    RemoveAllSessionDialog()
                        .environmentObject(viewModel)
                )
            }
            .buttonStyle(DeviceSessionButtonViewModifier(bgColor: Color.App.accent, width: width))
        }
        .frame(minWidth: 0, maxWidth: .infinity)
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
    }
    
    @ViewBuilder
    private var sizeReader: some View {
        GeometryReader { reader in
            Color.clear.onAppear {
                width = reader.size.width
            }
        }
    }
   
    @ViewBuilder
    private var loadingView: some View {
        if viewModel.isLoading {
            HStack {
                Spacer()
                LottieView(animation: .named("talk_logo_animation.json"))
                    .id(UUID())
                Spacer()
            }
            .frame(height: 52)
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .listRowInsets(.zero)
        }
    }
}

struct DeviceSessionButtonViewModifier: ButtonStyle {
    let bgColor: Color
    let width: CGFloat
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
        .frame(minWidth: 0, maxWidth: width < 800 ? width * 0.80 : width * 0.40)
        .buttonStyle(.plain)
        .padding(8)
        .background(bgColor)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .contentShape(RoundedRectangle(cornerRadius: 8))
        .fontWeight(.bold)
    }
}

struct DeviceSessionRow: View {
    @EnvironmentObject var viewModel: ManageSessionsViewModel
    let session: DeviceSession
    let width: CGFloat
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            list
            removeButton
        }
        .frame(minWidth: 0, maxWidth: .infinity)
        .padding(16)
        .background(Color.App.bgSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private var list: some View {
        ForEach(session.dict, id: \.0) { (title, value) in
            let isDeviceName = title == "ManageSessions.deviceName"
            let isNameAndCurrent = isDeviceName && session.current == true
            HStack(alignment: .top, spacing: 16) {
                Text(title)
                    .fontWeight(.bold)
                    .frame(minWidth: 128, alignment: .leading)
                    
                if isDeviceName {
                    Image(systemName: icon)
                        .scaledToFit()
                        .frame(width: 22, height: 22)
                        .foregroundStyle(Color.App.accent)
                }
                Text(value ?? "")
                    .multilineTextAlignment(.leading)
                    .foregroundStyle(.gray)
                    .font(Font.normal(.caption))
                
                if isNameAndCurrent {
                    Spacer()
                    Circle()
                        .fill(.green)
                        .frame(width: 12, height: 12)
                        .padding(.top, 6)
                }
            }
            
            Rectangle()
                .fill(Color.App.dividerPrimary.opacity(0.3))
                .frame(height: 1)
        }
    }
    
    private var icon: String {
        guard let type = session.deviceType else { return "" }
        switch type {
        case "Tablet":
            return "ipad.landscape"
        case "Mobile Phone":
            return "iphone"
        default:
            return "desktopcomputer.and.macbook"
        }
    }
    
    private var removeButton: some View {
        HStack(alignment: .center) {
            Button {
                AppState.shared.objectsContainer.appOverlayVM.dialogView = AnyView(
                    RemoveSessionDialog(session: session)
                        .environmentObject(viewModel)
                )
            } label: {
                Label(title: {
                    Text("ManageSessions.removeOnce")
                        .foregroundStyle(Color.white)
                }, icon: {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .foregroundStyle(Color.white)
                })
            }
            .buttonStyle(DeviceSessionButtonViewModifier(bgColor: Color.App.bgLargeButton, width: width))
        }
        .frame(minWidth: 0, maxWidth: .infinity)
    }
}

struct RemoveSessionDialog: View {
    let session: DeviceSession
    @EnvironmentObject var viewModel: ManageSessionsViewModel
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 16) {
            Text("ManageSessions.RemoveOneSession.title")
                .foregroundStyle(Color.App.textPrimary)
                .font(Font.bold(.subheadline))
                .multilineTextAlignment(.center)
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
            
            Text(attributedString)
                .foregroundStyle(Color.App.textPrimary)
                .font(Font.bold(.subheadline))
                .multilineTextAlignment(.center)
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
            
            HStack {
                Button {
                    Task {
                        try? await viewModel.removeSession(session: session)
                    }
                    AppState.shared.objectsContainer.appOverlayVM.dialogView = nil
                } label: {
                    Text("Genreal.confirm")
                        .foregroundStyle(Color.App.red)
                        .font(Font.normal(.body))
                        .frame(minWidth: 48, minHeight: 48)
                        .fontWeight(.medium)
                }

                Button {
                    AppState.shared.objectsContainer.appOverlayVM.dialogView = nil
                } label: {
                    Text("General.cancel")
                        .foregroundStyle(Color.App.textPlaceholder)
                        .font(Font.normal(.body))
                        .frame(minWidth: 48, minHeight: 48)
                        .fontWeight(.medium)
                }
            }
        }
        .frame(maxWidth: 320)
        .padding(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
        .background(MixMaterialBackground())
    }
    
    private var attributedString: AttributedString {
        let deviceName = session.name ?? ""
        let key = "ManageSessions.RemoveOneSession.subtitle".bundleLocalized()
        let string = String(format: key, deviceName)
        let attr = NSMutableAttributedString(string: string)
        let range = (attr.string as NSString).range(of: deviceName)
        attr.addAttributes([NSAttributedString.Key.foregroundColor: UIColor(named: "accent")!], range: range)
        return AttributedString(attr)
    }
}

struct RemoveAllSessionDialog: View {
    @EnvironmentObject var viewModel: ManageSessionsViewModel
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 16) {
            Text("ManageSessions.RemoveAllSessions.title")
                .foregroundStyle(Color.App.textPrimary)
                .font(Font.bold(.subheadline))
                .multilineTextAlignment(.center)
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                        
            Text("ManageSessions.RemoveAllSessions.subtitle")
                .foregroundStyle(Color.App.textPrimary)
                .font(Font.bold(.subheadline))
                .multilineTextAlignment(.center)
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
            HStack {
                Button {
                    Task {
                        try? await viewModel.removeAllSessions()
                    }
                    AppState.shared.objectsContainer.appOverlayVM.dialogView = nil
                } label: {
                    Text("Genreal.confirm")
                        .foregroundStyle(Color.App.red)
                        .font(Font.normal(.body))
                        .frame(minWidth: 48, minHeight: 48)
                        .fontWeight(.medium)
                }

                Button {
                    AppState.shared.objectsContainer.appOverlayVM.dialogView = nil
                } label: {
                    Text("General.cancel")
                        .foregroundStyle(Color.App.textPlaceholder)
                        .font(Font.normal(.body))
                        .frame(minWidth: 48, minHeight: 48)
                        .fontWeight(.medium)
                }
            }
        }
        .frame(maxWidth: 320)
        .padding(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
        .background(MixMaterialBackground())
    }
}

#Preview {
    ManageSessionsView()
}
