public enum DownloadFileState: Sendable {
    case started
    case completed
    case downloading
    case paused
    case error
    case undefined
}
