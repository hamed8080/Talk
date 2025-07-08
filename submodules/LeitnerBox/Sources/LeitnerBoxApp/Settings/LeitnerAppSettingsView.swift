//
// LeitnerAppSettingsView.swift
// Copyright (c) 2022 LeitnerBox
//
// Created by Hamed Hosseini on 10/28/22.

import AVFoundation
import CoreData
import SwiftUI

struct LeitnerAppSettingsView: View {
    @StateObject var viewModel = SettingsViewModel()
    @State private var showBackupSheet = false
    @AppStorage("pronounceDetailAnswer") private var pronounceDetailAnswer = false
    @State private var isShowingContactPicker = false    
    @State private var isShowingMessageComposer = false
    @State private var isShowingShareSheet = false
    @State private var showFilePicker = false
    @State private var isImporting = false
    @State private var showLoignSheet = false
    @State private var showRegister = false
    @State private var showForget = false
    @State private var showDeleteAccount = false
    @AppStorage("leitner_token") var leitnerToken: String?

    var body: some View {
        Form {
            Section(String(localized: .init("Voice"))) {
                Toggle(isOn: $pronounceDetailAnswer) {
                    Label("Prononce details of an answer ", systemImage: "mic")
                }

                Menu {
                    ForEach(viewModel.voices, id: \.self) { voice in
                        Button {
                            viewModel.setSelectedVoice(voice)
                        } label: {
                            let isSelected = viewModel.selectedVoice.identifier == voice.identifier
                            Text("\(isSelected ? "✔︎" : "") \(voice.name) - \(voice.language)")
                        }
                    }
                } label: {
                    HStack {
                        Label("Pronounce Voice", systemImage: "waveform")
                        Spacer()
                        Text("\(viewModel.selectedVoice.name) - \(viewModel.selectedVoice.language)")
                    }
                }
            }

            Section(String(localized: .init("Backup"))) {
                Button {
                    Task {
                        await viewModel.exportDB()
                    }
                } label: {
                    if viewModel.isBackuping {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(Color.accentColor)
                    } else {
                        Label("Export", systemImage: "cylinder.split.1x2")
                    }
                }
                
                Button {
                    showFilePicker = true
                } label: {
                    if isImporting {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(Color.accentColor)
                    } else {
                        Label("Import", systemImage: "square.and.arrow.down")
                    }
                }
            }
            
            if leitnerToken != nil {
                Section(String(localized: .init("logout"))) {
                    Button {
                        leitnerToken = nil
                    } label: {
                        Label("Logout", systemImage: "door.left.hand.open")
                            .foregroundStyle(.red)
                    }
                }
            } else {
                Section(String(localized: .init("Login"))) {
                    Button {
                        showLoignSheet.toggle()
                    } label: {
                        Label("Login", systemImage: "door.left.hand.open")
                            .foregroundStyle(.green)
                    }
                }
            }
            
            Section(String(localized: .init("Share"))) {
                Button {
                    isShowingContactPicker.toggle()
                } label: {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
            }
            let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
            HStack {
                Spacer()
                Image("icon", bundle: .module)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32, height: 32)
                Text("Version: \(version)")
                Spacer()
            }
            .frame(minHeight: 48)
            .clipShape(Rectangle())
            .listRowBackground(Color.clear)
        }
        .sheet(isPresented: $isShowingContactPicker) {
            LeitnerBoxContactPickerView { phoneNumber in
                viewModel.selectedPhoneNumber = phoneNumber
                // Check if the device can send SMS
                if let phoneNumber = phoneNumber {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                        if LeitnerBoxMessageComposerView.canSendText() {
                            isShowingMessageComposer = true // Open Messages app
                        } else {
                            isShowingShareSheet = true // Open Share Sheet for iPad
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $isShowingMessageComposer) {
            if let phone = viewModel.selectedPhoneNumber {
                LeitnerBoxMessageComposerView(recipients: [phone], body: "Hey! Check out this app: https://apps.apple.com/us/app/leitnerbox/id6738917632")
            }
        }
        .sheet(isPresented: $isShowingShareSheet) {
            if let phone = viewModel.selectedPhoneNumber {
                ShareSheet(activityItems: ["Hey! Check out this app: https://apps.apple.com/us/app/leitnerbox/id6738917632"])
            }
        }
        .fullScreenCover(isPresented: $showLoignSheet) {
            LeitnerBoxLoginDialog(showRegister: $showRegister, showForget: $showForget, showDeleteAccount: $showDeleteAccount)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .environmentObject(LeitnerBoxLoginViewModel())
        }
        .fullScreenCover(isPresented: $showRegister) {
            LeitnerBoxRegisterDialog()
                .environmentObject(LeitnerBoxRegisterViewModel())
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .fullScreenCover(isPresented: $showForget) {
            LeitnerBoxForgetDialog()
                .environmentObject(LeitnerBoxForgetViewModel())
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .fullScreenCover(isPresented: $showDeleteAccount) {
            LeitnerBoxDeleteAccountDialog()
                .environmentObject(LeitnerBoxDeleteAccountViewModel())
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .fileImporter(isPresented: $showFilePicker, allowedContentTypes: [.item]) { result in
            switch result {
            case .success(let fileURL):
                if fileURL.lastPathComponent.contains(".sqlite") {
                    isImporting = true
                    Task {
                        await viewModel.importDB(url: fileURL)
                        NotificationCenter.default.post(name: Notification.Name("RELAOD_CONTEXT"), object: nil)
                    }
                }
            case .failure(let failure):
                break
            }
        }
        .onChange(of: viewModel.backupFile?.fileURL) { newValue in
            if newValue != nil {
                showBackupSheet = true
            }
        }
        .sheet(isPresented: $showBackupSheet) {
            if .iOS == true {
                Task {
                    await viewModel.deleteBackupFile()
                }
            }
        } content: {
            if let fileUrl = viewModel.backupFile?.fileURL {
                LeitnerBoxAppActivityViewControllerWrapper(activityItems: [fileUrl])
            } else {
                EmptyView()
            }
        }
    }
}

#if DEBUG
struct SettingsView_Previews: PreviewProvider {
    struct Preview: View {
        @StateObject var viewModel = SettingsViewModel()

        var body: some View {
            LeitnerAppSettingsView()
                .environment(\.managedObjectContext, PersistenceController.shared.viewContext)
                .environmentObject(viewModel)
        }
    }

    static var previews: some View {
        NavigationStack {
            Preview()
        }
        .previewDisplayName("SettingsView")
    }
}
#endif
