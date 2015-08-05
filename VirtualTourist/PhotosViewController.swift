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
    
    var selectedIndexes = [NSIndexPath]() // it keeps tracks of which item is selected to delete.
    var shouldUpdateBottomButton = false
    var destination: Location!
    var sharedSession: NSURLSession?
    lazy var fetchedResultsController: NSFetchedResultsController = {
        let fetchRequest = NSFetchRequest(entityName: "Photo")
        fetchRequest.sortDescriptors = []
        fetchRequest.predicate = NSPredicate(format: "destination == %@", self.destination)
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext(), sectionNameKeyPath: nil, cacheName: nil)
        return fetchedResultsController
        }()
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var noImageLabel: UITextField!
    @IBOutlet weak var button: UIButton!
    
    @IBAction func backButtonTapped(sender: AnyObject) {
        self.performSegueWithIdentifier("GoBack", sender: self)
    }
    @IBAction func buttonTapped(sender: AnyObject) {
        if selectedIndexes.isEmpty {
            self.button.hidden = true
            deleteAllPics()
            VTClient.sharedInstance.getImagesFromFlickr(self.destination) { success, dic, error in
                dispatch_async(dispatch_get_main_queue()) {
                    if success == true && dic != nil {
                        VTClient.sharedInstance.handleFlickr(success, dics: dic!, destination: self.destination) { completed in
                            self.updateBottomButton()
                        }
                    } else {
                        self.noImageLabel.hidden = false
                    }
                }
            }
        } else {
            self.deleteSelectedPics()
        }
    }
    
    // NSFetchrResultsControllerDelegate
    
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
        self.button.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.8)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        mapView.addAnnotation(destination!.pin)
        mapView.showAnnotations([destination!.pin], animated: true)
        if self.shouldUpdateBottomButton {
            self.updateBottomButton()
        }
    }
    
    func sharedContext() -> NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext!
    }
    
    // collectionView
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return self.fetchedResultsController.sections?.count ?? 0
    }
    
    func configureCell(cell: PhotoCell, atIndexPath indexPath: NSIndexPath) {
        let pic = self.fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        if pic.image != nil {
            cell.imageView.image = pic.image
            if cell.activityIndicator.isAnimating() {
                cell.activityIndicator.stopAnimating()
            }
        } else {
            let imgURL = NSURL(string: pic.imageUrlString!)
            let request: NSURLRequest = NSURLRequest(URL: imgURL!)
            let task = self.sharedSession?.dataTaskWithRequest(request) { data, res, error in
                if error == nil {
                    let image = UIImage(data: data)
                    ImageHandler.sharedImageHandler.storeImage(image!, identifier: pic.id!)
                    dispatch_async(dispatch_get_main_queue()) {
                        cell.imageView.image = image
                        if cell.activityIndicator.isAnimating() {
                            cell.activityIndicator.stopAnimating()
                        }
                    }
                }
            }
            task!.resume()
        }
        if cell.activityIndicator.isAnimating() {
           cell.activityIndicator.stopAnimating()
        }
        if let index = find(self.selectedIndexes, indexPath) {
            cell.view.backgroundColor = UIColor.lightGrayColor().colorWithAlphaComponent(0.5)
            cell.view.hidden = false
        } else {
            cell.view.hidden = true
        }
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("PhotoCell", forIndexPath: indexPath) as! PhotoCell
        cell.backgroundColor = UIColor.grayColor()
        cell.activityIndicator.startAnimating()
        self.configureCell(cell, atIndexPath: indexPath)
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sectionInfo = self.fetchedResultsController.sections![section] as? NSFetchedResultsSectionInfo
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
        self.updateBottomButton()
    }
    
    // Functions related to deleting pics
    
    func deleteAllPics() {
        for pic in fetchedResultsController.fetchedObjects as! [Photo] {
            pic.destination = nil
            if pic.image != nil {
                ImageHandler.sharedImageHandler.deleteImage(pic.image!, withIdentifier: pic.id!)
            }
            self.sharedContext().deleteObject(pic)
        }
        CoreDataStackManager.sharedInstance().saveContext()
    }
    
    func deleteSelectedPics() {
        var picsToDelete = [Photo]()
        for indexPath in self.selectedIndexes {
            picsToDelete.append(fetchedResultsController.objectAtIndexPath(indexPath) as! Photo)
        }
        for pic in picsToDelete {
            pic.destination = nil
            if pic.image != nil {
                ImageHandler.sharedImageHandler.deleteImage(pic.image!, withIdentifier: pic.id!)
            }
            self.sharedContext().deleteObject(pic)
        }
        selectedIndexes = [NSIndexPath]()
        CoreDataStackManager.sharedInstance().saveContext()
    }
    
    func updateBottomButton() {
        self.button.hidden = false
        if self.selectedIndexes.count > 0 {
            self.button.setTitle("Remove Selected Pics", forState: .Normal)
            self.button.sizeToFit()
        } else {
            self.button.setTitle("Get New Collection", forState: .Normal)
            self.button.sizeToFit()
        }
    }
    
}
