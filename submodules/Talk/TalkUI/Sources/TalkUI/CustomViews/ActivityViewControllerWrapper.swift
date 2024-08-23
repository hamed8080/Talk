//
//  ActivityViewControllerWrapper.swift
//  TalkUI
//
//  Created by Hamed Hosseini on 10/16/21.
//

import LinkPresentation
import SwiftUI

public struct ActivityViewControllerWrapper: UIViewControllerRepresentable {
    var activityItems: [URL]
    var title: String?
    var applicationActivities: [UIActivity]?

    public init(activityItems: [URL], title: String? = nil, applicationActivities: [UIActivity]? = nil) {
        self.activityItems = activityItems
        self.title = title
        self.applicationActivities = applicationActivities
    }

    public func makeUIViewController(context _: Context) -> some UIActivityViewController {
        let vc = UIActivityViewController(activityItems: [LinkMetaDataManager(url: activityItems.first!, title: title)], applicationActivities: nil)
        return vc
    }

    public func updateUIViewController(_: UIViewControllerType, context _: Context) {}
}

public final class LinkMetaDataManager: NSObject, UIActivityItemSource {
    let url: URL
    let title: String?

    public init(url: URL, title: String?) {
        self.url = url
        self.title = title
    }

    public func activityViewControllerPlaceholderItem(_: UIActivityViewController) -> Any {
        ""
    }

    public func activityViewController(_: UIActivityViewController, itemForActivityType _: UIActivity.ActivityType?) -> Any? {
        url
    }

    public func activityViewControllerLinkMetadata(_: UIActivityViewController) -> LPLinkMetadata? {
        let image = UIImage(named: "global_app_icon")
        let imageProvider = NSItemProvider(object: image!)
        let metadata = LPLinkMetadata()
        metadata.originalURL = url
        metadata.url = url
        metadata.imageProvider = imageProvider
        metadata.title = title ?? url.lastPathComponent
        return metadata
    }
}
