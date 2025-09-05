//
//  PhotoLibrary.swift
//  TalkUI
//
//  Created by Hamed Hosseini on 9/5/25.
//

import Foundation
import Photos
import SwiftUI
import TalkViewModels

@MainActor
public final class PhotoLibrary {    
    public static let shared = PhotoLibrary()
    private init() {}
    
    public func onSaveVideoAction(url: URL) async {
        
        let authStatus = await requestAuthorizationIfNeeded()
        
        guard authStatus == .authorized || authStatus == .limited else {
            showToast(failed: true, authorizationFailed: true)
            return
        }
        
        do {
            // Perform the PhotoLibrary change transaction
            try await PHPhotoLibrary.shared().performChanges { @Sendable in
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
            }
            
            try? FileManager.default.removeItem(at: url)
            
            // UI feedback on main actor
            showToast(failed: false)
        } catch {
            showToast(failed: true)
        }
    }
    
    private func showToast(failed: Bool, authorizationFailed: Bool = false) {
        if authorizationFailed {
            AppState.shared.objectsContainer.appOverlayVM.dialogView = AnyView(SaveToAlbumDialogView())
            return
        }
        let icon = Image(systemName: "externaldrive.badge.checkmark")
            .fontWeight(.semibold)
            .foregroundStyle(Color.App.white)
        
        AppState.shared.objectsContainer.appOverlayVM.toast(
            leadingView: icon,
            message: failed ? "" : "General.videoSaved",
            messageColor: failed ? Color.red : Color.App.white
        )
    }
    
    private func requestAuthorizationIfNeeded() async -> PHAuthorizationStatus {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        
        if status == .notDetermined {
            return await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        } else {
            return status
        }
    }
}
