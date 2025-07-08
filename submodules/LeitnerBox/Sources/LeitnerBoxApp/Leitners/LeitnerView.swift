//
// LeitnerView.swift
// Copyright (c) 2022 LeitnerBox
//
// Created by Hamed Hosseini on 10/28/22.

import AVFoundation
import CoreData
import SwiftUI

struct LeitnerView: View {
    @EnvironmentObject var viewModel: LeitnerViewModel
    @EnvironmentObject var navViewModel: NavigationViewModel
    @Environment(\.horizontalSizeClass) private var sizeClass
    @AppStorage("showedLoginDialog") private var showedLoginDialog: Bool?
    @State private var showLoignSheet = false
    @State private var showRegister = false
    @State private var showForget = false
    @State private var showDeleteAccount = false

    var body: some View {
        view
        .leitnerBoxCustomDialog(isShowing: $viewModel.showEditOrAddLeitnerAlert) {
            EditOrAddLeitnerView()
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name(rawValue: "RELAOD_CONTEXT"))) { _ in
            viewModel.reload()
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
        .onAppear {
            if showedLoginDialog == nil {
                showedLoginDialog = true
                showLoignSheet = true
            }
        }
    }
    
    @ViewBuilder
    private var view: some View {
        if UIDevice.current.userInterfaceIdiom == .pad && sizeClass != .compact {
            ipadFull
        } else {
            compactLayout
        }
    }
    
    private var compactLayout: some View {
        NavigationStack(path: $navViewModel.paths) {
              SidebarListView()
                  .navigationDestination(for: NavigationType.self) { type in
                      LeitnerNavigationView(type: type)
                  }
          }
    }
    
    private var ipadFull: some View {
        NavigationSplitView(columnVisibility: $navViewModel.columnVisibility) {
            SidebarListView()
        } detail: {
            NavigationStack(path: $navViewModel.paths) {
                if viewModel.leitners.isEmpty {
                    EmptyLeitnerAnimation()
                } else if viewModel.selectedLeitner == nil {
                    Text("Nothing has been selected")
                }
            }.navigationDestination(for: NavigationType.self) { type in
                LeitnerNavigationView(type: type)
            }
        }
    }
}

struct SidebarListView: View {
    @EnvironmentObject var viewModel: LeitnerViewModel

    var body: some View {
        List {
            if !viewModel.leitners.isEmpty {
                leitnersSection
            }
        }
        .overlay(alignment: .center) {
            if viewModel.leitners.isEmpty {
                EmptyLeitnerAnimation()
            }
        }
        .toolbar {
            leadingToolbarView
        }
        .refreshable {
            viewModel.load()
        }
        .listStyle(.insetGrouped)
        .tint(.clear)
        .navigationTitle("Leitner Box")
    }

    private var leitnersSection: some View {
        Section(String(localized: .init("Leitners"))) {
            ForEach(viewModel.leitners) { leitner in
                Button {
                    viewModel.setLeithner(leitner)
                } label: {
                    LeitnerRowView(leitner: leitner)
                        .foregroundStyle(Color.primary)
                }
                .id("\(leitner.id)-\(leitner.objectID)")
                .listRowBackground(viewModel.selectedLeitner?.id == leitner.id ? Color(.systemFill) : Color(.secondarySystemGroupedBackground))
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    deleteActionView(leitner)
                }
            }
        }
    }

    @ViewBuilder
    private func deleteActionView(_ leitner: Leitner) -> some View {
        Button(role: .destructive) {
            viewModel.delete(leitner)
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }
    
    private var leadingToolbarView: ToolbarItemGroup<some View> {
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            Button {
                viewModel.clear()
                viewModel.showEditOrAddLeitnerAlert.toggle()
            } label: {
                HStack {
                    Image(systemName: "plus")
                        .accessibilityHint("Add Item")
                        .foregroundStyle(Color.accentColor)
                    Spacer()
                }
            }
            Button {
                NavigationViewModel.shared.appendSetting()
            } label: {
                HStack {
                    Image(systemName: "gear")
                        .foregroundStyle(Color.red)
                    Spacer()
                }
            }
        }
    }
}

#if DEBUG
struct LeitnerView_Previews: PreviewProvider {
    struct Preview: View {
        var viewModel: LeitnerViewModel {
            _ = MockDatabase.shared.generateAndFillLeitner()
            return LeitnerViewModel(viewContext: PersistenceController.shared.viewContext)
        }

        var body: some View {
            LeitnerView()                
                .environmentObject(viewModel)
        }
    }

    static var previews: some View {
        NavigationStack {
            Preview()
        }
        .previewDisplayName("LeitnerView")
    }
}
#endif
