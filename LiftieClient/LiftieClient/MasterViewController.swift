//
//  MasterViewController.swift
//  LiftieClient
//
//  Created by Gary Shirk on 2/22/15.
//  Copyright (c) 2015 garyshirk. All rights reserved.
//

import UIKit
import CoreData
import SwiftyJSON

class MasterViewController: UITableViewController, NSFetchedResultsControllerDelegate
    {
    
    var detailViewController: DetailViewController? = nil
    var managedObjectContext: NSManagedObjectContext? = nil
    
    var isInitialSyncComplete = false
    
    let resortIds: [String]! = ["aspen-mountain", "bolton-valley", "canyons", "diamondpeak", "gore-mountain"]
    //let resortIds: [String]! = ["canyons"]

    override func awakeFromNib() {
        super.awakeFromNib()
        if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
            self.clearsSelectionOnViewWillAppear = false
            self.preferredContentSize = CGSize(width: 320.0, height: 600.0)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        //self.navigationItem.leftBarButtonItem = self.editButtonItem()

//        let addButton = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: "insertNewObject:")
//        self.navigationItem.rightBarButtonItem = addButton
        
        if let split = self.splitViewController {
            let controllers = split.viewControllers
            self.detailViewController = controllers[controllers.count-1].topViewController as? DetailViewController
        }
        
        // loop through the resort ids
        for var index = 0; index < resortIds.count; ++index {
            
            let id = self.resortIds[index]
    
            DataAccessManager.getLiftieDataForId(id, withSuccess: {(liftieData) -> Void in
            
                let json = JSON(data: liftieData)
                
                var liftTimeRetrieved: Double = 0
                
                if let timeRetrieved = json["timestamp"]["lifts"].double as Double? {
                    liftTimeRetrieved = timeRetrieved
                }
                
                if let resortId = json["id"].stringValue as NSString? {
                    println("resort id: \(resortId)")
                    
                    var request = NSFetchRequest(entityName: "Resort")
                    request.predicate = NSPredicate(format: "id = %@", resortId)
                    let context = self.fetchedResultsController.managedObjectContext
                    
                    if let results = context.executeFetchRequest(request, error: nil) as? [Resort] {
                        
                        var count = results.count
                        
                        if count > 0 {
                            
                            println("liftTimeRetrieved: \(liftTimeRetrieved)")
                            
                            var liftTimeStored = (results[0].liftTimestamp)!.timeIntervalSince1970
                            println("liftTimeStored: \(liftTimeStored)")
                            
                            var nowTimeLong = round((NSDate().timeIntervalSince1970 * 1000))
                            println("nowTimeLong: \(nowTimeLong)")
                            
                            let oneMinute: Double = 60 * 1000
                            let deltaTime = nowTimeLong - liftTimeStored
                            if deltaTime > oneMinute {
                                var resort = results[0]
                                resort.liftTimestamp = NSDate(timeIntervalSince1970: liftTimeRetrieved)
                                println("resort.liftTimeStamp: \(resort.liftTimestamp)")
                            }
                            
                        } else {
                            
                            var resortName: NSString = "error"
                            if let name = json["name"].stringValue as NSString? {
                                resortName = name
                            }
                            
                            var liftTimeStamp = NSDate(timeIntervalSince1970: liftTimeRetrieved)
                            
                            self.createNewResortWithId(resortId, resortName: resortName, liftTimeStamp: liftTimeStamp)
                        }
                    }
                }
                
//                if let liftStatusDict = json["lifts"]["status"].dictionaryValue as Dictionary? {
//                    //println("lift dictionary: \(liftStatusDict)")
//                    
//                    for (liftName, liftStatus) in liftStatusDict {
//                        //println("\(liftName) \t \(liftStatus)")
//                    }
//                }
                
            })
            
            if index == self.resortIds.count - 1 {
                self.isInitialSyncComplete = true
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func createNewResortWithId(resortId: NSString, resortName: NSString, liftTimeStamp: NSDate) {
        
        let newResort = NSEntityDescription.insertNewObjectForEntityForName("Resort", inManagedObjectContext: self.managedObjectContext!) as? Resort
        
        newResort?.id = resortId
        newResort?.name = resortName
        newResort?.liftTimestamp = liftTimeStamp
    }
    
    
    func insertNewObject(sender: AnyObject) {
        
//        let context = self.fetchedResultsController.managedObjectContext
//        let entity = self.fetchedResultsController.fetchRequest.entity!
//        let newManagedObject = NSEntityDescription.insertNewObjectForEntityForName(entity.name!, inManagedObjectContext: context) as NSManagedObject
//             
//        // If appropriate, configure the new managed object.
//        // Normally you should use accessor methods, but using KVC here avoids the need to add a custom class to the template.
//        newManagedObject.setValue(NSDate(), forKey: "id")
//             
//        // Save the context.
//        var error: NSError? = nil
//        if !context.save(&error) {
//            // Replace this implementation with code to handle the error appropriately.
//            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
//            //println("Unresolved error \(error), \(error.userInfo)")
//            abort()
//        }
    }

    // MARK: - Segues

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showResortDetail" {
            if let indexPath = self.tableView.indexPathForSelectedRow() {
            let object = self.fetchedResultsController.objectAtIndexPath(indexPath) as NSManagedObject
                let controller = (segue.destinationViewController as UINavigationController).topViewController as DetailViewController
                //controller.detailItem = object
                controller.resort = object as Resort
                controller.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem()
                controller.navigationItem.leftItemsSupplementBackButton = true
            }
        }
    }

    // MARK: - Table View

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return self.fetchedResultsController.sections?.count ?? 0
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo = self.fetchedResultsController.sections![section] as NSFetchedResultsSectionInfo
        return sectionInfo.numberOfObjects
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as UITableViewCell
        self.configureCell(cell, atIndexPath: indexPath)
        return cell
    }

    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }

    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            let context = self.fetchedResultsController.managedObjectContext
            context.deleteObject(self.fetchedResultsController.objectAtIndexPath(indexPath) as NSManagedObject)
                
            var error: NSError? = nil
            if !context.save(&error) {
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                //println("Unresolved error \(error), \(error.userInfo)")
                abort()
            }
        }
    }

    func configureCell(cell: UITableViewCell, atIndexPath indexPath: NSIndexPath) {
        let object = self.fetchedResultsController.objectAtIndexPath(indexPath) as NSManagedObject
        cell.textLabel!.text = object.valueForKey("id")!.description
    }

    // MARK: - Fetched results controller

    var fetchedResultsController: NSFetchedResultsController {
        if _fetchedResultsController != nil {
            return _fetchedResultsController!
        }
        
        let fetchRequest = NSFetchRequest()
        // Edit the entity name as appropriate.
        let entity = NSEntityDescription.entityForName("Resort", inManagedObjectContext: self.managedObjectContext!)
        fetchRequest.entity = entity
        
        // Set the batch size to a suitable number.
        fetchRequest.fetchBatchSize = 20
        
        // Edit the sort key as appropriate.
        let sortDescriptor = NSSortDescriptor(key: "id", ascending: false)
        let sortDescriptors = [sortDescriptor]
        
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        // Edit the section name key path and cache name if appropriate.
        // nil for section name key path means "no sections".
        let aFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext!, sectionNameKeyPath: nil, cacheName: "Master")
        aFetchedResultsController.delegate = self
        _fetchedResultsController = aFetchedResultsController
        
    	var error: NSError? = nil
    	if !_fetchedResultsController!.performFetch(&error) {
    	     // Replace this implementation with code to handle the error appropriately.
    	     // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
             //println("Unresolved error \(error), \(error.userInfo)")
    	     abort()
    	}
        
        return _fetchedResultsController!
    }    
    var _fetchedResultsController: NSFetchedResultsController? = nil

//    func controllerWillChangeContent(controller: NSFetchedResultsController) {
//        self.tableView.beginUpdates()
//    }
//
//    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
//        switch type {
//            case .Insert:
//                self.tableView.insertSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
//            case .Delete:
//                self.tableView.deleteSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
//            default:
//                return
//        }
//    }
//
//    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
//        switch type {
//            case .Insert:
//                tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
//            case .Delete:
//                tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
//            case .Update:
//                self.configureCell(tableView.cellForRowAtIndexPath(indexPath!)!, atIndexPath: indexPath!)
//            case .Move:
//                tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
//                tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
//            default:
//                return
//        }
//    }

    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        //self.tableView.endUpdates()
        
        if isInitialSyncComplete {
            let context = self.fetchedResultsController.managedObjectContext
            var error: NSError? = nil
            if !context.save(&error) {
                println(error?.localizedDescription)
            }
            
            self.tableView.reloadData()
        }
    }
}

