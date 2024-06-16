//
//  LogView.swift
//  Talk
//
//  Created by hamed on 6/27/22.
//

import Chat
import Logger
import SwiftUI
import TalkViewModels
import TalkUI

struct LogView: View {
    @EnvironmentObject var viewModel: LogViewModel

    var body: some View {
        List {
            loadingView
            searchNotFound
            ForEach(viewModel.filtered) {
                LogRow(log: $0)
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                    .transition(.asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .trailing)))
            }
        }
        .toolbar(.hidden)
        .animation(.easeInOut, value: viewModel.filtered.count)
        .listStyle(.plain)
        .safeAreaInset(edge: .top) {
            VStack {
                HStack {
                    trailingToolbars
                    Spacer()
                }
                .padding(.leading, 4)
                searchView
            }
            .padding(4)
            .background(MixMaterialBackground(color: Color.App.bgToolbar).ignoresSafeArea())
        }
        .normalToolbarView(title: "Logs.title", type: LogNavigationValue.self, trailingView: EmptyView())
        .sheet(isPresented: $viewModel.shareDownloadedFile) {
            if let logFileURL = viewModel.logFileURL {
                ActivityViewControllerWrapper(activityItems: [logFileURL], title: logFileURL.lastPathComponent)
            }
        }
    }

    @ViewBuilder
    private var searchView: some View {
        TextField("General.searchHere".bundleLocalized(), text: $viewModel.searchText)
            .keyboardType(.default)
            .padding(4)
            .applyAppTextfieldStyle(topPlaceholder: "", innerBGColor: Color.App.bgSendInput, minHeight: 42, isFocused: true) {

            }
            .noSeparators()
            .listRowBackground(Color.App.bgSecondary)
    }

    @ViewBuilder
    private var searchNotFound: some View {
        if viewModel.searchText.isEmpty == false, viewModel.filtered.count < 1 {
            HStack {
                Image(systemName: "doc.text.magnifyingglass")
                    .foregroundColor(Color.App.textSecondary.opacity(0.8))
                Text("General.nothingFound")
                    .foregroundColor(Color.App.textSecondary.opacity(0.8))
            }
        }
    }

    @ViewBuilder
    private var loadingView: some View {
        if viewModel.isFiltering {
            ListLoadingView(isLoading: .constant(viewModel.isFiltering))
                .id(-1)
                .listRowSeparator(.hidden)
                .listRowInsets(.zero)
                .listRowBackground(Color.clear)
                .padding([.top, .bottom])
                .padding([.top, .bottom], viewModel.isFiltering ? 8 : 0)
                .animation(.easeInOut, value: viewModel.isFiltering)
        }
    }

    @ViewBuilder var trailingToolbars: some View {
        HStack {
            trashButton
            saveButton
            Menu {
                Button {
                    viewModel.type = nil
                } label: {
                    if viewModel.type == nil {
                        Image(systemName: "checkmark")
                    }
                    Text("General.all")
                }
                ForEach(LogEmitter.allCases) { item in
                    Button {
                        viewModel.type = item
                    } label: {
                        if viewModel.type == item {
                            Image(systemName: "checkmark")
                        }
                        Text(item.title)
                    }
                }
            } label: {
                Label("", systemImage: "line.3.horizontal.decrease.circle")
            }
        }
    }

    @ViewBuilder
    private var saveButton: some View {
        Button {
            Task {
                await viewModel.startExporting()
            }
        } label: {
            Label {
                Text("Thread.export".bundleLocalized())
            } icon: {
                Image(systemName: "square.and.arrow.up")
            }
        }
    }

    @ViewBuilder
    private var trashButton: some View {
        Button {
            viewModel.deleteLogs()
        } label: {
            Label {
                Text("General.delete".bundleLocalized())
            } icon: {
                Image(systemName: "trash")
            }
        }
    }
}

struct LogView_Previews: PreviewProvider {
    static var previews: some View {
        LogView()
            .environmentObject(LogViewModel())
    }
}
