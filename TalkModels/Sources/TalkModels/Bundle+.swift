//
//  Bundle+.swift
//
//
//  Created by hamed on 7/24/24.
//

import Foundation
import ZipArchive

public extension Bundle {
    static let bundleName = "MyBundle"
    static let bundleNameWithBundleExt = "MyBundle.bundle"
    static let unpackedFolderName = "UnzippedFiles"
    static let zipName = "MyBundle.bundle.zip"
    static let bundleURL = "https://github.com/hamed8080/bundle/raw/main/MyBundle.bundle.zip"

    static func getBundle() -> Bundle {
        let bundleURL = unpackedPath()?.appendingPathComponent(zipName)
        if let bundleURL = bundleURL, let myBundle = Bundle(url: bundleURL) {
            return myBundle
        }
        return .main
    }

    class var documentsURL: URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
    }
    
    class func bunldePath() -> URL? {
        documentsURL?.appendingPathComponent(bundleNameWithBundleExt)
    }

    class func unpackedPath() -> URL? {
        documentsURL?.appendingPathComponent(unpackedFolderName)
    }

    class func st(completion: @escaping (Bool) -> Void) {
        guard let diskPath = bunldePath(), let unpackedURL = unpackedPath() else { return }
        if FileManager.default.fileExists(atPath: diskPath.path) {
            completion(true)
            return
        }
        Task {
            guard let url = URL(string: bundleURL) else {
                completion(false)
                return
            }
            let req = URLRequest(url: url)
            guard let downloadedFileURL = try? await URLSession.shared.download(for: req).0 else {
                completion(false)
                return
            }
            do {
                try FileManager.default.moveItem(at: downloadedFileURL, to: diskPath)
                // Create the directory for unzipped files if it doesn't exist
                if !FileManager.default.fileExists(atPath: unpackedURL.path) {
                    try FileManager.default.createDirectory(at: unpackedURL, withIntermediateDirectories: true, attributes: nil)
                }
                // Unzip the file
                SSZipArchive.unzipFile(atPath: diskPath.path, toDestination: unpackedURL.path)
                completion(true)
            } catch {
                print(error)
                completion(false)
            }
        }
    }
}
