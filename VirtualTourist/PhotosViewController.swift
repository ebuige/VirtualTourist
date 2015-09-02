//
//  PhotosViewController.swift
//  VirtualTourist
//
//  Created by Troutslayer33 on 8/4/15.
//  Copyright (c) 2015 Troutslayer33. All rights reserved.
//

import UIKit
import CoreData
import MapKit

class PhotosViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, MKMapViewDelegate, NSFetchedResultsControllerDelegate {
    
    var insertedIndexPaths: [NSIndexPath]!
    var deletedIndexPaths: [NSIndexPath]!
    var updatedIndexPaths: [NSIndexPath]!
    var selectedIndexes = [NSIndexPath]()
    var destination: Location!
    var sharedSession: NSURLSession?
    var UpdateNewCollectionButton = true
    var noImageFound = false
    
    
    @IBOutlet weak var noImageLabel: UILabel!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var button: UIButton!
    
    
    // View life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        var error: NSError?
        fetchedResultsController.performFetch(&error)
        if let error = error {
            abort()
        }
        fetchedResultsController.delegate = self
        self.sharedSession = NSURLSession.sharedSession()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        mapView.addAnnotation(destination!.pin)
        mapView.showAnnotations([destination!.pin], animated: true)
        if self.UpdateNewCollectionButton {
            self.updateNewCollectionButton()
        }
        if self.noImageFound {
            self.noImageLabel.text = "no images found"
        }
    }
    

    
    
    
    
    @IBAction func goBackToMap(sender: AnyObject) {
        self.performSegueWithIdentifier("BackToMap", sender: self)
    }
    
    @IBAction func getNewCollection(sender: AnyObject) {
            self.button.hidden = true
            deleteAllPhotos()
            VTClient.sharedInstance.getImagesFromFlickr(self.destination) { success, pic, error in
                dispatch_async(dispatch_get_main_queue()) {
                    if success == true && pic != nil {
                        VTClient.sharedInstance.handleFlickr(success, pics: pic!, destination: self.destination) { completed in
                            self.updateNewCollectionButton()
                            self.noImageLabel.text = ""
                        }
                    } else {
                        self.noImageLabel.text = "no images found" }
                    }
                }
            }
    
    // MARK: - Core Data Convenience
    
    func sharedContext() -> NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext!
    }

    
    // Mark: - Fetched Results Controller
  
    lazy var fetchedResultsController: NSFetchedResultsController = {
        let fetchRequest = NSFetchRequest(entityName: "Photo")
        fetchRequest.sortDescriptors = []
        fetchRequest.predicate = NSPredicate(format: "destination == %@", self.destination)
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext(), sectionNameKeyPath: nil, cacheName: nil)
        return fetchedResultsController
        }()
   

            
    // Fetched Results Controller Delegate
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        insertedIndexPaths = [NSIndexPath]()
        deletedIndexPaths = [NSIndexPath]()
        updatedIndexPaths = [NSIndexPath]()
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch type{
        case .Insert:
            insertedIndexPaths.append(newIndexPath!)
            break
        case .Delete:
            deletedIndexPaths.append(indexPath!)
            break
        case .Update:
            updatedIndexPaths.append(indexPath!)
        default:
            break
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        collectionView.performBatchUpdates({() -> Void in
            for indexPath in self.insertedIndexPaths {
                self.collectionView.insertItemsAtIndexPaths([indexPath])
            }
            for indexPath in self.deletedIndexPaths {
                self.collectionView.deleteItemsAtIndexPaths([indexPath])
            }
            for indexPath in self.updatedIndexPaths {
                self.collectionView.reloadItemsAtIndexPaths([indexPath])
            }
            }, completion: nil)
    }
    
    
    // collectionView
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return self.fetchedResultsController.sections?.count ?? 0
    }
    
    func configureCell(cell: PhotoCell, atIndexPath indexPath: NSIndexPath) {
        let pic = self.fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        if pic.image != nil {
            if cell.activityIndicator.isAnimating() {
                cell.activityIndicator.stopAnimating()
                cell.activityIndicator.hidden = true
            }
            cell.imageView.image = pic.image
        } else {
            let imgURL = NSURL(string: pic.imageUrlString!)
            let request: NSURLRequest = NSURLRequest(URL: imgURL!)
            let task = self.sharedSession?.dataTaskWithRequest(request) { data, res, error in
                if error == nil {
                    let image = UIImage(data: data)
                    ImageHandler.sharedImageHandler.storeImage(image!, identifier: pic.id!)
                    dispatch_async(dispatch_get_main_queue()) {
                        if cell.activityIndicator.isAnimating() {
                            cell.activityIndicator.stopAnimating()
                            cell.activityIndicator.hidden = true
                        }
                        cell.imageView.image = image
                    }
                }
            }
            task!.resume()
        }
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("PhotoCell", forIndexPath: indexPath) as! PhotoCell
        cell.backgroundColor = UIColor.grayColor()
        cell.activityIndicator.hidden = false
        cell.activityIndicator.startAnimating()
        self.configureCell(cell, atIndexPath: indexPath)
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sectionInfo = self.fetchedResultsController.sections![section] as? NSFetchedResultsSectionInfo
        if sectionInfo?.numberOfObjects == 0 {
            self.button.hidden = true
        }
        return sectionInfo!.numberOfObjects
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! PhotoCell
        if let index = find(self.selectedIndexes, indexPath) {
            self.selectedIndexes.removeAtIndex(index)
        } else {
            self.selectedIndexes.append(indexPath)
        }
        self.configureCell(cell, atIndexPath: indexPath)
        self.deleteSelectedPhoto()
    }
    
    // Deletes all photos in current collection when called
    
    func deleteAllPhotos() {
        for photos in fetchedResultsController.fetchedObjects as! [Photo] {
            photos.destination = nil
            if photos.image != nil {
                ImageHandler.sharedImageHandler.deleteImage(photos.image!, withIdentifier: photos.id!)
            }
            self.sharedContext().deleteObject(photos)
        }
        CoreDataStackManager.sharedInstance().saveContext()
    }
    
    // Deletes single photo when called after user taps on it
    
    func deleteSelectedPhoto() {
        var photoToDelete = [Photo]()
        for indexPath in self.selectedIndexes {
            photoToDelete.append(fetchedResultsController.objectAtIndexPath(indexPath) as! Photo)
        }
        for photo in photoToDelete {
            photo.destination = nil
            if photo.image != nil {
                ImageHandler.sharedImageHandler.deleteImage(photo.image!, withIdentifier: photo.id!)
            }
            self.sharedContext().deleteObject(photo)
        }
        selectedIndexes = [NSIndexPath]()
        CoreDataStackManager.sharedInstance().saveContext()
    }
    
    func updateNewCollectionButton() {
        self.button.hidden = false
        self.button.sizeToFit()
    }
    
}
