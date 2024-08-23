//
//  LocationMessageRequest+.swift
//  TalkExtensions
//
//  Created by hamed on 4/15/22.
//

import Foundation
import TalkModels
import Chat

public extension LocationMessageRequest {
    init(item: LocationItem, model: SendMessageModel) {
        let coordinate = Coordinate(lat: item.location.latitude, lng: item.location.longitude)
        self = LocationMessageRequest(mapCenter: coordinate,
                                         threadId: model.threadId,
                                         userGroupHash: model.userGroupHash ?? "",
                                         mapZoom: 17,
                                         mapImageName: item.name,
                                         textMessage: model.textMessage)
    }
}
