//
//  Photo.swift
//  VirtualTourist
//
//  Created by Troutslayer33 on 8/4/15.
//  Copyright (c) 2015 Troutslayer33. All rights reserved.
//

import Foundation
import CoreData
import UIKit

class Photo: NSManagedObject {
    
    @NSManaged var id: String?
    @NSManaged var imageUrlString: String?
    @NSManaged var destination: Location?
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dic: [String: String], context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)
        super.init(entity: entity!, insertIntoManagedObjectContext: context)
        self.imageUrlString = dic["imageUrlString"]
        self.id = dic["id"]
    }
    
    var image: UIImage? {
        get {
            return ImageHandler.sharedImageHandler.imageWithIdentifier(self.id)
        }
    }
    
}