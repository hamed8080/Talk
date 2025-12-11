//
//  DetailAddOrEditContactSheetView.swift
//  Talk
//
//  Created by hamed on 5/7/24.
//

import SwiftUI
import TalkViewModels

public struct DetailAddOrEditContactSheetView: View {
    @EnvironmentObject private var viewModel: ContactsViewModel

    public var body: some View {
        Color.clear
            .sheet(isPresented: $viewModel.showAddOrEditContactSheet, onDismiss: onAddOrEditDisappeared) {
                if #available(iOS 16.4, macOS 13.3, tvOS 16.4, watchOS 9.4, *) {
                    AddOrEditContactView()
                        .environmentObject(viewModel)
                        .environment(\.layoutDirection, Language.isRTL ? .rightToLeft : .leftToRight)
                        .onDisappear {
                            onAddOrEditDisappeared()
                        }
                }
            }
    }

    private func onAddOrEditDisappeared() {
        /// Clearing the view for when the user cancels the sheet by dropping it down.
        viewModel.successAdded = false
        viewModel.showAddOrEditContactSheet = false
        viewModel.addContact = nil
        viewModel.editContact = nil
    }
}

struct DetailAddOrEditContactSheetView_Previews: PreviewProvider {
    static var previews: some View {
        DetailAddOrEditContactSheetView()
    }
}
