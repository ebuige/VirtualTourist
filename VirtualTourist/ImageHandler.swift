//
//  ImageHandler.swift
//  VirtualTourist
//
//  Created by Troutslayer33 on 8/4/15.
//  Copyright (c) 2015 Troutslayer33. All rights reserved.
//

import UIKit
import Foundation

class ImageHandler {
    
    static let sharedImageHandler = ImageHandler()
    var inMemoryCache = NSCache()
    
    // MARK: - Retreiving images
    
    func imageWithIdentifier(identifier: String?) -> UIImage? {
        if identifier == nil || identifier! == "" {
            return nil
        }
        let path = pathForIdentifier(identifier!)
        if let image = inMemoryCache.objectForKey(path) as? UIImage {
            return image
        }
        if NSFileManager.defaultManager().fileExistsAtPath(path) {
            let data = NSFileManager.defaultManager().contentsAtPath(path)
            let image = UIImage(data: data!)
            return image
        }
        return nil
    }
    
    // MARK: - Saving images
    
    func storeImage(image: UIImage, identifier: String) {
        let path = pathForIdentifier(identifier)
        if inMemoryCache.objectForKey(path) == nil {
            inMemoryCache.setObject(image, forKey: path)
        }
        let data = UIImageJPEGRepresentation(image, 1.0)
        data.writeToFile(path, atomically: true)
    }
    
    // MARK: - Helper
    
    func pathForIdentifier(identifier: String) -> String {
        let documentsDirectoryURL: NSURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first as! NSURL
        let fullURL = documentsDirectoryURL.URLByAppendingPathComponent(identifier)
        
        return fullURL.path!
    }
    
    func deleteImage(image: UIImage, withIdentifier identifier: String) {
        let manager = NSFileManager.defaultManager()
        let path = pathForIdentifier(identifier)
        var error: NSError?
        manager.removeItemAtPath(path, error: &error)
    }
    
}
