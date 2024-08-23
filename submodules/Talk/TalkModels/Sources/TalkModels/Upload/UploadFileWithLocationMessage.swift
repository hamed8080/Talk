import Chat

public class UploadFileWithLocationMessage: HistoryMessageBaseCalss, UploadProtocol {
    public var locationRequest: LocationMessageRequest

    public init(locationRequest: LocationMessageRequest, message: Message) {
        self.locationRequest = locationRequest
        super.init(message: message)
    }
}
