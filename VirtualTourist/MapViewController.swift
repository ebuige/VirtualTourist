//
//  MapViewController.swift
//  
//
//  Created by Troutslayer33 on 8/4/15.
//
//

import UIKit
import CoreData
import MapKit

class MapViewController: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView! { didSet { self.enableUserPin() } }
    var destination: Location?
    var destinations = [Location]()
    var noImage = false
    var picturesFetched = false
    var filePath : String {
        let manager = NSFileManager.defaultManager()
        let url = manager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first as! NSURL
        return url.URLByAppendingPathComponent("mapRegionArchive").path!
    }
    
    // attempt to restore map - cannot get span to correctly reset
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.restoreMapRegion(false)
    }
    
    // retrieve all stored destinations and then place pins in all stored locations
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        destinations = fetchAllDestinations()
        if destinations.count > 0 {
            mapAllThePlaces(destinations)
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    func saveMapRegion() {
        
        // Place the "center" and "span" of the map into a dictionary
        // The "span" is the width and height of the map in degrees.
        // It represents the zoom level of the map.
        
        mapView.region.span.latitudeDelta = mapView.region.span.latitudeDelta * 0.99
        mapView.region.span.longitudeDelta = mapView.region.span.longitudeDelta * 0.99
        
        let dictionary = [
            "latitude" : mapView.region.center.latitude,
            "longitude" : mapView.region.center.longitude,
            "latitudeDelta" : mapView.region.span.latitudeDelta,
            "longitudeDelta" : mapView.region.span.longitudeDelta
        ]
        
      //  println("latD: \(mapView.region.span.latitudeDelta), lonD: \(mapView.region.span.longitudeDelta)")
        // Archive the dictionary into the filePath
        NSKeyedArchiver.archiveRootObject(dictionary, toFile: filePath)
    }
    
    // retrieve stored map values and try to set the map region to the saved values .... this not working even though saved values are correct
    
    func restoreMapRegion(animated: Bool) {
        if let regionDictionary = NSKeyedUnarchiver.unarchiveObjectWithFile(filePath) as? [String : AnyObject] {
            let longitude = regionDictionary["longitude"] as! CLLocationDegrees
            let latitude = regionDictionary["latitude"] as! CLLocationDegrees
            let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            let longitudeDelta = regionDictionary["latitudeDelta"] as! CLLocationDegrees
            let latitudeDelta = regionDictionary["longitudeDelta"] as! CLLocationDegrees
            let span = MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
            let savedRegion = MKCoordinateRegion(center: center, span: span)
            mapView.setRegion(savedRegion, animated: animated)
        //    println("lat: \(latitude), lon: \(longitude), latD: \(latitudeDelta), lonD: \(longitudeDelta)")
        }
    }
    
    // fetch all stored map locations
    
    func fetchAllDestinations() -> [Location] {
        var error: NSError?
        let fetchRequest = NSFetchRequest(entityName: "Location")
        let results = sharedContext().executeFetchRequest(fetchRequest, error: &error)
        if error != nil {
            self.displayAlertView("Sorry, an error occured fetching this data...")
        }
        return results as! [Location]
    }
    
    // standard alert view controller 
    
    func displayAlertView(message: String) {
        let alertController = UIAlertController(title: "Loading Locations Failed", message: message, preferredStyle: .Alert)
        let action = UIAlertAction(title: "OK", style: .Default) { (action) in
            self.dismissViewControllerAnimated(true, completion: nil)
        }
        alertController.addAction(action)
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    // using the retrieved stored locations restore pins on map
    
    func mapAllThePlaces(places: [Location]) {
        var annotations = places.map() {
            place -> MKPointAnnotation in
            return place.pin
        }
        self.mapView.addAnnotations(annotations)
    }
    
    func sharedContext() -> NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext!
    }
    
    lazy var temporaryContext: NSManagedObjectContext = {
        var context = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.MainQueueConcurrencyType)
        context.persistentStoreCoordinator = self.sharedContext().persistentStoreCoordinator
        return context
        }()
    
    func enableUserPin() {
        let lpgr = UILongPressGestureRecognizer(target: self, action: "action:")
        lpgr.minimumPressDuration = 2
        self.mapView.addGestureRecognizer(lpgr)
    }
    
    func action(gestureRecognizer: UIGestureRecognizer) {
        let gestureState = gestureRecognizer.state
        switch gestureState {
        case .Began:
            createDragEffect(gestureRecognizer)
        case .Changed:
            createDragEffect(gestureRecognizer)
        case .Ended:
            destinationSet(gestureRecognizer)
        default:
            break
        }
    }
    
    func createDragEffect(gestureRecognizer: UIGestureRecognizer){
        var temporaryDestinations = [MKPointAnnotation]()
        let wayPoints = gestureRecognizer.locationInView(self.mapView)
        let location: CLLocationCoordinate2D = self.mapView.convertPoint(wayPoints, toCoordinateFromView: self.mapView)
        var temporaryDestination = Location(wayPoints: location, context: temporaryContext)
        temporaryDestinations.append(temporaryDestination.pin)
        self.mapView.addAnnotation(temporaryDestination.pin)
    }
    
    // set destination in core data
    
    func destinationSet(gestureRecognizer: UIGestureRecognizer) {
        self.mapView.removeAnnotations(self.mapView.annotations)
        let wayPoints = gestureRecognizer.locationInView(self.mapView)
        let location: CLLocationCoordinate2D = self.mapView.convertPoint(wayPoints, toCoordinateFromView: self.mapView)
        self.destination = Location(wayPoints: location, context: sharedContext())
        self.destinations.append(destination!)
        CoreDataStackManager.sharedInstance().saveContext()
        self.mapAllThePlaces(self.destinations)
        self.fetchPictures(self.destinations.last!)
    }
    
    func fetchPictures(destination: Location) {
        if self.destination!.pictures.isEmpty {
            VTClient.sharedInstance.getImagesFromFlickr(self.destination!) { success, dic, error in
                dispatch_async(dispatch_get_main_queue()) {
                    if success == true && dic != nil {
                        VTClient.sharedInstance.handleFlickr(success, dics: dic!, destination: self.destination!) { completed in self.picturesFetched = true }
                    }
                }
            }
        } else {
            self.noImage = true
        }
    }
    
    func mapView(mapView: MKMapView!, didSelectAnnotationView view: MKAnnotationView!) {
        let pinCoordinate = view.annotation.coordinate
        for destination in self.destinations {
            if destination.pin.coordinate.latitude == pinCoordinate.latitude {
                if destination.pin.coordinate.longitude == pinCoordinate.longitude {
                    self.destination = destination
                    if self.destination!.pictures.isEmpty {
             //       if self.destination != destinations.last || self.picturesFetched == false {
             //           println("do not perform seque 2")
             //           VTClient.sharedInstance.getImagesFromFlickr(self.destination!) { success, dic, error in
             //               dispatch_async(dispatch_get_main_queue()) {
             //                   if success == true && dic != nil {
            //                        VTClient.sharedInstance.handleFlickr(success, dics: dic!, destination: self.destination!) { completed in
            //                            println("perform segue 1")
             //                           self.performSegueWithIdentifier("showPhotos", sender: self)
            //                        }
            //                    } else {
            //                        self.noImage = true
            //                        self.performSegueWithIdentifier("showPhotos", sender: self)
            //                        println("no images found")
            //                    }
            //                }
            //            }
            //        }
            //        println("perform segue 2")
                        self.noImage = true }
            //            self.performSegueWithIdentifier("showPhotos", sender: self)}
                    self.performSegueWithIdentifier("showPhotos", sender: self)
                  //  self.noImage = true
                }
            }
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showPhotos" {
            let pvc = segue.destinationViewController as! PhotosViewController
            pvc.destination = self.destination
            pvc.UpdateNewCollectionButton = true
            if self.noImage {
                pvc.noImageFound = true
                pvc.UpdateNewCollectionButton = false
            }
        }
    }
    
}

extension MapViewController : MKMapViewDelegate {
    
    func mapView(mapView: MKMapView!, regionDidChangeAnimated animated: Bool) {
        saveMapRegion()
    }
}
