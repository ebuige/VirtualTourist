//
//  VTClient.swift
//  VirtualTourist
//
//  Created by Troutslayer33 on 8/4/15.
//  Copyright (c) 2015 Troutslayer33. All rights reserved.
//

import Foundation
import UIKit

class VTClient: NSObject {
    
    static let sharedInstance = VTClient()
    var session: NSURLSession
    
    override init() {
        session = NSURLSession.sharedSession()
    }
    
    func getImagesFromFlickr(destination: Location, completionHandler: ((success: Bool, dics: [[String: String]]?, error: NSError?) -> Void)) {
        
        println("flicker client") 
        let methodArguments = [
            VTClient.Keys.METHOD: VTClient.Constants.METHOD,
            VTClient.Keys.API_KEY: VTClient.Constants.API_KEY,
            VTClient.Keys.SAFE_SEARCH: VTClient.Constants.SAFE_SEARCH,
            VTClient.Keys.LAT: destination.lat!,
            VTClient.Keys.LON: destination.lon!,
            VTClient.Keys.EXTRAS: VTClient.Constants.EXTRAS,
            VTClient.Keys.FORMAT: VTClient.Constants.FORMAT,
            VTClient.Keys.NO_JSON_CALLBACK: VTClient.Constants.NO_JSON_CALLBACK,
        ]
        var dics = [[String: String]]()
        let urlString = VTClient.Constants.BaseURL + escapedParameters(methodArguments)
        let url = NSURL(string: urlString)
        let request = NSMutableURLRequest(URL: url!)
        request.HTTPMethod = "POST"
        let task = session.dataTaskWithRequest(request) { data, response, downloadingError in
            if let res = response as? NSHTTPURLResponse {
                if res.statusCode != 200 {
                    completionHandler(success: false, dics: nil, error: downloadingError)
                }
            }
            if downloadingError != nil {
                completionHandler(success: false, dics: nil, error: downloadingError)
            } else {
                var error: NSError?
                let parsedResult = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments, error: &error) as! [String: AnyObject]
                let info = parsedResult["photos"] as! [String: AnyObject]
                if let photoDictionary = info["photo"] as? [[String: AnyObject]] {
                    if photoDictionary.count > 0 {
                        for item in photoDictionary {
                            let imageUrlString = item["url_m"] as! String
                            let id = item["id"] as! String
                            let dic = ["imageUrlString": imageUrlString, "id": id]
                            dics.append(dic)
                        }
                        completionHandler(success: true, dics: dics, error: nil)
                    } else {
                        completionHandler(success: false, dics: nil, error: nil)
                    }
                }
            }
        }
        task.resume()
        
    }
    
    func handleFlickr(success: Bool, dics: [[String: String]], destination: Location,  completionHandler: ( Bool -> Void )) {
        for item in dics {
            let picture = Photo(dic: item, context: CoreDataStackManager.sharedInstance().managedObjectContext!)
            picture.destination = destination
        }
        CoreDataStackManager.sharedInstance().saveContext()
        completionHandler(true)
    }
    
    func escapedParameters(parameters: [String : AnyObject]) -> String {
        var urlVars = [String]()
        for (key, value) in parameters {
            let stringValue = "\(value)"
            let escapedValue = stringValue.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
            urlVars += [key + "=" + "\(escapedValue!)"]
        }
        return (!urlVars.isEmpty ? "?" : "") + join("&", urlVars)
    }
}