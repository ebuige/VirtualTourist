//
//  Location.swift
//  VirtualTourist
//
//  Created by Troutslayer33 on 8/4/15.
//  Copyright (c) 2015 Troutslayer33. All rights reserved.
//

import Foundation
import MapKit
import CoreData

class Location: NSManagedObject {
    
    @NSManaged var lat: NSNumber?
    @NSManaged var lon: NSNumber?
    @NSManaged var pictures: [Photo]
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(wayPoints: CLLocationCoordinate2D, context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entityForName("Location", inManagedObjectContext: context)
        super.init(entity: entity!, insertIntoManagedObjectContext: context)
        self.lat = wayPoints.latitude as Double
        self.lon = wayPoints.longitude as Double
    }
    
    var pin: MKPointAnnotation {
        let location = CLLocationCoordinate2D(latitude: self.lat as! Double, longitude: self.lon as! Double)
        let annotation = MKPointAnnotation()
        annotation.coordinate = location
        return annotation
    }
    
}
