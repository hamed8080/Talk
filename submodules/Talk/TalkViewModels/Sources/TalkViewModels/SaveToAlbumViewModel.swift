//
//  SaveToAlbumViewModel.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 7/26/25.
//

import TalkModels
import Photos
import UIKit
import SwiftUI

@MainActor
public final class SaveToAlbumViewModel {
    private let fileURL: URL
    
    public init(fileURL: URL) {
        self.fileURL = fileURL
    }
    
    private func saveImageToAlbum() throws {
        let data = try Data(contentsOf: fileURL)
        guard let image = try UIImage(data: data) else {
            throw SaveToAlbumError.failedToSaveImageData
        }
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
    }
    
    public func save() async throws {
        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        switch status {
        case .authorized:
            try self.saveImageToAlbum()
        case .notDetermined:
            // Only request if the status is not determined
            let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
            if status == .authorized {
                try self.saveImageToAlbum()
            } else {
                throw SaveToAlbumError.notAuthorized
            }
        default:
            throw SaveToAlbumError.notAuthorized
        }
    }
    
    public enum SaveToAlbumError: Error {
        case notAuthorized
        case failedToSaveImageData
    }
}

