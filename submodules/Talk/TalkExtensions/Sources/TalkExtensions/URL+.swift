//
//  File.swift
//  
//
//  Created by hamed on 2/13/24.
//

import Foundation

public extension URL {
    var widgetThreaId: Int? {
        if !absoluteString.contains("Widget") { return nil }
        let threadIdString = absoluteString.replacingOccurrences(of: "Widget://link-", with: "")
        guard let threadId = Int(threadIdString) else { return nil }
        return threadId
    }

    var openThreadUserName: String? {
        if !absoluteString.contains("showUser") { return nil }
        let userName = absoluteString.replacingOccurrences(of: "showUser:User?userName=", with: "")
        return userName
    }

    var decodedOpenURL: URL? {
        if !absoluteString.contains("openURL") { return nil }
        let encodedURL = absoluteString.replacingOccurrences(of: "openURL:url?encodedValue=", with: "")
        guard
            let data = Data(base64Encoded: encodedURL),
            let decodedString = String(data: data, encoding: .utf8)?
                .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)?
                .replacingOccurrences(of: "%23", with: "#"),
            let decodedURL = properSchemeURL(decodedString)
        else { return nil }
        return decodedURL
    }

    private func properSchemeURL(_ decodedString: String) -> URL? {
        if scheme == nil || !containsAllowedScheme(decodedString) {
            return URL(string: "http://\(decodedString)")
        } else {
            return URL(string: decodedString)
        }
    }

    private func containsAllowedScheme(_ stringUrl: String) -> Bool {
        let allowedSchemes = ["https", "http"]
        var containtsHttpOrHttps = false
        allowedSchemes.forEach { scheme in
            if stringUrl.contains(scheme) {
                containtsHttpOrHttps = true
            }
        }
        return containtsHttpOrHttps
    }
    
    public func createHardLink(for fileURL: URL, ext: String) -> URL? {
        let fileManager = FileManager.default
        let originalURL = URL(fileURLWithPath: fileURL.path())
        
        // Get the directory of the original file
        let directory = originalURL.deletingLastPathComponent()
        
        // Create a new name for the hard link with the specified extension
        let newFileName = originalURL.lastPathComponent + ".\(ext)"
        let newFileURL = directory.appendingPathComponent(newFileName)
        
        // Create a hard link
        try? fileManager.linkItem(at: originalURL, to: newFileURL)
        return newFileURL
    }
}
