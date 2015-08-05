//
//  VTConstants.swift
//  VirtualTourist
//
//  Created by Troutslayer33 on 8/4/15.
//  Copyright (c) 2015 Troutslayer33. All rights reserved.
//

import Foundation

extension VTClient {
    
    struct Constants {
        static let API_KEY = "790d5a15e28a8262777d00a3de2312df"
        static let My_API_Secret = "c52a28c70f7a9c9a"
        static let BaseURL = "https://api.flickr.com/services/rest/"
        static let METHOD = "flickr.photos.search"
        static let EXTRAS = "url_m"
        static let SAFE_SEARCH = "1"
        static let FORMAT = "json"
        static let NO_JSON_CALLBACK = "1"
    }
    
    struct Keys {
        static let METHOD = "method"
        static let API_KEY = "api_key"
        static let SAFE_SEARCH = "safe_search"
        static let LAT = "lat"
        static let LON = "lon"
        static let EXTRAS = "extras"
        static let FORMAT = "format"
        static let NO_JSON_CALLBACK = "nojsoncallback"
    }
    
}