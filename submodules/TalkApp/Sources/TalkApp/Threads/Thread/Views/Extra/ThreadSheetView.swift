//
//  ThreadSheetView.swift
//  Talk
//
//  Created by hamed on 3/13/23.
//

import SwiftUI
import TalkUI
import TalkViewModels
import TalkModels
import Chat

/// We have to use this due to in the ThreadView we used let viewModel in it will never trigger the sheet.
//struct SheetEmptyBackground: View {
//    @EnvironmentObject var viewModel: ThreadViewModel
//    var sheetBinding: Binding<Bool> { Binding(get: { viewModel.sheetType != nil }, set: { _ in }) }
//
//    var body: some View {
//        Color.clear
//            .sheet(isPresented: sheetBinding) {
//                ThreadSheetView(sheetBinding: sheetBinding)
//                    .environmentObject(viewModel)
//                    .environmentObject(viewModel.attachmentsViewModel)
//            }
//    }
//}

struct ThreadSheetView: View {
//    @EnvironmentObject var viewModel: ThreadViewModel
    @Binding var sheetBinding: Bool

    var body: some View {
        EmptyView()
//        switch viewModel.sheetType {
//        case .attachment:
//            EmptyView()
//        case .datePicker:
//            DateSelectionView(showDialog: $sheetBinding) { startDate, endDate in
//                viewModel.sheetType = nil
//                viewModel.setupExportMessage(startDate: startDate, endDate: endDate)
//            }
//            .onDisappear {
//                closeSheet()
//            }
//        case .exportMessagesFile:
//            if let exportFileUrl = viewModel.exportMessagesViewModel.filePath {
//                ActivityViewControllerWrapper(activityItems: [exportFileUrl])
//                    .onDisappear {
//                        viewModel.exportMessagesViewModel.deleteFile()
//                        closeSheet()
//                    }
//            } else {
//                EmptyView()
//            }
//        case .threadPicker:
//            EmptyView()
//        case .filePicker:
//            EmptyView()
//        case .locationPicker:
//            EmptyView()
//        case .galleryPicker:
//            EmptyView()
//        default:
//            Text("Sheet \(viewModel.sheetType.debugDescription) not implemented yet.")
//        }
    }

    private func closeSheet() {
//        sheetBinding = false
//        viewModel.sheetType = nil
//        viewModel.animateObjectWillChange()
    }

    private func onThreadPickerResult(_ conversation: Conversation?, _ contact: Contact?) {
//        let conversarionId = conversation?.id ?? -1
//        let contactUserId = contact?.userId ?? -1
//        if conversarionId == viewModel.threadId || contactUserId == viewModel.thread.partner {
//            forwardToItself()
//        } else {
//            viewModel.sendMessageViewModel.openDestinationConversationToForward(conversation, contact)
//            viewModel.selectedMessagesViewModel.clearSelection() // it is essential to clean up the ui after the user tap on either a contact or a thread
//        }
    }

    private func forwardToItself() {
//        let messages = viewModel.selectedMessagesViewModel.selectedMessages.compactMap{$0.message}
//        AppState.shared.setupForwardRequest(from: viewModel.threadId, to: viewModel.threadId, messages: messages)
//        viewModel.sheetType = nil
//        viewModel.animateObjectWillChange()
//        viewModel.selectedMessagesViewModel.clearSelection() // it is essential to clean up the ui after the user tap on either a contact or a thread
//        Task { @MainActor in
//            await viewModel.scrollVM.scrollToBottomIfIsAtBottom()
//        }
    }
}

struct ThreadSheetView_Previews: PreviewProvider {
    static var previews: some View {
        ThreadSheetView(sheetBinding: .constant(true))
    }
}
