//
//  BundleManager.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 3/3/25.
//

import Foundation
import ZipArchive

@MainActor
public class BundleManager {
    private let bundleName = "MyBundle.bundle"
    private let bundleNameZipName = "MyBundle_v\(BundleManager.version).zip"
    private let unpackedFolderName = "UnzippedFiles"
    // https://github.com/hamed8080/bundle/archive/refs/tags/v1.97.zip
    private let bundleURL = "aHR0cHM6Ly9naXRodWIuY29tL2hhbWVkODA4MC9idW5kbGUvYXJjaGl2ZS9yZWZzL3RhZ3MvdjEuOTcuemlw"
    private static let version = "1.97"

    public init(){}

    public enum ManagerError: Error {
        case badURL
    }

    public func getBundle() -> Bundle {
        guard let bundleURL = bundleFilePath else { return .main }
        let myBundle = Bundle(url: bundleURL)
        return myBundle ?? .main
    }

    public var hasBundle: Bool {
        bundleFilePath != nil
    }

    private var bundleFilePath: URL? {
        documentsURL?.appendingPathComponent(bundleName)
    }

    private var documentsURL: URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
    }

    private func bunldeZipPath() -> URL? {
        documentsURL?.appendingPathComponent(bundleNameZipName)
    }

    private func unpackedFolderPath() -> URL? {
        documentsURL?.appendingPathComponent(unpackedFolderName)
    }

    private func unpackedPathFilePath() -> URL? {
        unpackedFolderPath()?.appendingPathComponent(bundleName)
    }

    // Start downloading if the bundle does not exist.
    public func st() async throws -> Bool {
        guard let zipPath = bunldeZipPath(), let unpackedFolderURL = unpackedFolderPath() else { return false }
        if let fileURL = unpackedPathFilePath(), FileManager.default.fileExists(atPath: fileURL.path()) { return true }
        let dlFileURL = try await dl()
        try FileManager.default.moveItem(at: dlFileURL, to: zipPath)
        try md(unpackedFolderURL)
        try uz(zipPath, unpackedFolderURL)
        try delZF()
        try mv()
        try de()
        setVersion()
        return true
    }

    // Download the bundle.
    private func dl() async throws -> URL {
        guard let url = URL(string: bundleURL.fromBase64() ?? "") else { throw ManagerError.badURL }
        let req = URLRequest(url: url)
        let downloadedFileURL = try await URLSession.shared.download(for: req).0
        return downloadedFileURL
    }

    // Create the directory for unzipped files if it doesn't exist
    private func md(_ unpackedURL: URL) throws {
        if !FileManager.default.fileExists(atPath: unpackedURL.path()) {
            try FileManager.default.createDirectory(at: unpackedURL, withIntermediateDirectories: true, attributes: nil)
        }
    }

    // Unzip the file
    private func uz(_ diskPath: URL, _ unpackedURL: URL) throws {
        SSZipArchive.unzipFile(atPath: diskPath.path(), toDestination: unpackedURL.path())
    }

    // Move MyBundle.bundle file insdide the UnzippedFiles/bundle-0.0.1 to Documents/MyBundle.bundle
    private func mv() throws {
        guard let folderNamePath = try folderNamePath() else { return }
        let url = folderNamePath.appendingPathComponent(bundleName)

        //Move to Documents/MyBundle.bundle
        guard let newDest = bundleFilePath else { return }
        try FileManager.default.moveItem(at: url, to: newDest)
    }

    // Unpacked folder name from the github like: UnzippedFiles/bundle-0.0.1
    private func folderNamePath() throws -> URL? {
        guard let unpackedFolder = unpackedFolderPath() else { return nil }
        let paths = try FileManager.default.contentsOfDirectory(atPath: unpackedFolder.path())
        guard let folderName = paths.first(where: {$0.contains("bundle")}) else { return nil }
        return unpackedFolder.appendingPathComponent(folderName)
    }

    // Delete the name UnzippedFolder.
    private func de() throws {
        guard let unizpFolder = try unpackedFolderPath() else { return }
        try FileManager.default.removeItem(atPath: unizpFolder.path())
    }

    // Delete the zip file to make it possible to move the file into the documents path.
    private func delZF() throws {
        guard let zipFile = bunldeZipPath() else { return }
        try FileManager.default.removeItem(atPath: zipFile.path())
    }
    
    // Automatically update bundle if it's lower than the version we need
    public func shouldUpdate() async throws -> Bool {
        let userDefaultversion = UserDefaults.standard.string(forKey: "version")
        if userDefaultversion != BundleManager.version {
            // Remove old unzip folder at Documents/UnzippedFiles/
            if let url = unpackedFolderPath() {
                try? FileManager.default.removeItem(atPath: url.path())
            }
            // Remove old file at Documents/MyBundle.bundle
            if let url = bundleFilePath {
                try? FileManager.default.removeItem(atPath: url.path())
            }
            await try st()
            return true
        } else {
            return false
        }
    }

    private func setVersion() {
        // Store version number for the next launch
        UserDefaults.standard.setValue(BundleManager.version, forKey: "version")
    }
    
    public func isBundleDownloaded() -> Bool {
        if let url = bundleFilePath {
            return FileManager.default.fileExists(atPath: url.path())
        }
        return false
    }
}
