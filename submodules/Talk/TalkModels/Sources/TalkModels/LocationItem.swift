import CoreLocation
import MapKit

public struct LocationItem: Identifiable, Sendable {
    public var id = UUID().uuidString
    public let name: String
    public let description: String
    public var location: CLLocationCoordinate2D
    public var coordinate: MKCoordinateRegion {
        get {
            MKCoordinateRegion(center: location, span: MKCoordinateSpan(latitudeDelta: 50, longitudeDelta: 50))
        }
        set {
            location = newValue.center
        }
    }

    public init(id: String = UUID().uuidString, name: String, description: String, location: CLLocationCoordinate2D) {
        self.id = id
        self.name = name
        self.description = description
        self.location = location
    }
}
