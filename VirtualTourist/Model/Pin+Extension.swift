//
//  Pin+Extension.swift
//  VirtualTourist
//
//  Created by nang saw on 04/02/2021.
//

import MapKit

extension Pin: MKAnnotation {
    public var coordinate: CLLocationCoordinate2D {
        let latDegrees = CLLocationDegrees(latitude)
        let longDegrees = CLLocationDegrees(longitude)
        return CLLocationCoordinate2D(latitude: latDegrees, longitude: longDegrees)
    }
}
