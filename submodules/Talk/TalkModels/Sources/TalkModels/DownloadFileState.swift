public enum DownloadFileState: Sendable {
    case started
    case completed
    case downloading
    case thumbnail
    case paused
    case thumbnailDownloaing
    case error
    case undefined
}
