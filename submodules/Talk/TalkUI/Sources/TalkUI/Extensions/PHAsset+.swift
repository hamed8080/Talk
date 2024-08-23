import Photos

public extension PHAsset {
    var originalFilename: String? {
        PHAssetResource.assetResources(for: self).first?.originalFilename
    }
}
