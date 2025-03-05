//
//  AttachmentFile.swift
//  TalkModels
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Foundation

public enum AttachmentType: Sendable {
    case gallery
    case file
    case drop
    case map
    case contact
}

public struct AttachmentFile: Identifiable, Hashable {
    public static func == (lhs: AttachmentFile, rhs: AttachmentFile) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public let id: UUID
    public let type: AttachmentType

    public var url: URL?
    public var request: Any?

    public var icon: String? {
        if type == .map {
            return "map.fill"
        } else if type == .file {
            return systemImageNameForFileExtension((request as? URL)?.fileExtension)
        } else if type == .drop {
            return systemImageNameForFileExtension((request as? DropItem)?.ext)
        } else if type == .contact {
            return "person.fill"
        } else {
            return nil
        }
    }

    public var title: String? {
        if type == .map {
            return (request as? LocationItem)?.description
        } else if type == .gallery {
            return (request as? ImageItem)?.fileName
        } else if type == .file {
            return (request as? URL)?.fileName
        } else if type == .drop {
            return (request as? DropItem)?.name
        } else if type == .contact {
            return "contact"
        } else {
            return nil
        }
    }

    public var subtitle: String? {
        if type == .map {
            return (request as? LocationItem)?.name
        } else if type == .gallery {
            return ((request as? ImageItem)?.data.count ?? 0)?.toSizeString(locale: Language.preferredLocale, bundle: Language.preferedBundle)
        } else if type == .file {
            let item = request as? URL
            var size = 0
            if let fileSize = try? item?.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                size = fileSize
            }
            return "\(size.toSizeString(locale: Language.preferredLocale, bundle: Language.preferedBundle) ?? "") - \((request as? URL)?.fileExtension.uppercased() ?? "")"
        } else if type == .drop {
            let item = request as? DropItem
            return "\((item?.data?.count ?? 0)?.toSizeString(locale: Language.preferredLocale, bundle: Language.preferedBundle) ?? "") - \(item?.ext?.uppercased() ?? "")"
        } else if type == .contact {
            return "contact"
        } else {
            return nil
        }
    }

    public init(id: UUID = UUID(), type: AttachmentType = .file, url: URL? = nil, request: Any? = nil) {
        self.id = id
        self.type = type
        self.url = url
        self.request = request
    }

    private func systemImageNameForFileExtension(_ string: String?) -> String {
        switch string {
        case ".mp4", ".avi", ".mkv":
            return "play.rectangle.fill"
        case ".mp3", ".m4a":
            return "play.circle.fill"
        case ".docx", ".pdf", ".xlsx", ".txt", ".ppt":
            return "doc.circle.fill"
        case ".zip", ".rar", ".7z":
            return "doc.zipper"
        default:
            return "doc.fill"
        }
    }
}
