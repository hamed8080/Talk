//
//  Coordinate+.swift
//  TalkExtensions
//
//  Created by hamed on 3/14/23.
//

import MapKit
import Chat

public extension Coordinate {
    var location: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: lat, longitude: lng)
    }
}

extension Coordinate: Identifiable {
    public var id: String {
        "\(lat),\(lng)"
    }
}
